import { existsSync, readFileSync, readJSON, readJSONSync } from 'fs-extra';
import { join } from 'path';

import c from '../colors';
import { output } from '../log';

import { getCommandOutput } from './subprocess';

export interface BlockedInstallScript {
  name: string;
  version: string;
}

const LOCKFILE_MANAGERS: readonly [string, string][] = [
  ['package-lock.json', 'npm'],
  ['npm-shrinkwrap.json', 'npm'],
  ['pnpm-lock.yaml', 'pnpm'],
  ['yarn.lock', 'yarn'],
  ['bun.lock', 'bun'],
  ['bun.lockb', 'bun'],
];

function detectLockfileManagers(rootDir: string): Set<string> {
  const managers = new Set<string>();
  for (const [lockfile, manager] of LOCKFILE_MANAGERS) {
    if (existsSync(join(rootDir, lockfile))) {
      managers.add(manager);
    }
  }
  return managers;
}

function hasNpmLockfileDisabled(rootDir: string): boolean {
  const npmrcPath = join(rootDir, '.npmrc');
  if (!existsSync(npmrcPath)) {
    return false;
  }

  try {
    for (const line of readFileSync(npmrcPath, 'utf-8').split('\n')) {
      const trimmed = line.trim();
      if (trimmed === '' || trimmed.startsWith('#') || trimmed.startsWith(';')) {
        continue;
      }
      const match = trimmed.match(/^package-lock\s*=\s*(false|0)\s*$/i);
      if (match) {
        return true;
      }
    }
  } catch (e) {
    return false;
  }

  return false;
}

export function logAmbiguousLockfiles(rootDir: string): void {
  const managers = detectLockfileManagers(rootDir);
  if (managers.size <= 1) {
    return;
  }

  try {
    const { packageManager } = readJSONSync(join(rootDir, 'package.json'));
    if (typeof packageManager === 'string') {
      return;
    }
  } catch (e) {
    // fall through
  }

  output.write(
    `${c.strong('Ambiguous package manager:')}\n\n` +
      `  Multiple lockfiles are present (${[...managers].join(', ')}), so blocked install scripts cannot be checked reliably.\n` +
      `  Remove stale lockfiles or set ${c.input('packageManager')} in package.json.\n\n`,
  );
}

/**
 * `npm install-scripts ls` compares the tree against npm's own `allowScripts` map, which yarn and
 * pnpm never write. It therefore reports every install script in a yarn or pnpm project as
 * blocked, even when that package manager ran it, so the check has to know who did the install.
 *
 * Only a positive signal counts. `rootDir` is the app package, which in a workspace holds neither
 * a lockfile nor a `packageManager` field, and guessing npm there reports blocked scripts for an
 * install npm never performed.
 */
export async function isNpmProject(rootDir: string): Promise<boolean> {
  try {
    const { packageManager } = await readJSON(join(rootDir, 'package.json'));
    if (typeof packageManager === 'string') {
      return packageManager.split('@')[0] === 'npm';
    }
  } catch (e) {
    // no package.json, or an unreadable one: fall through to the lockfiles
  }

  const managers = detectLockfileManagers(rootDir);
  if (managers.size === 1) {
    return managers.has('npm');
  }
  if (managers.size > 1) {
    return false;
  }

  if (existsSync(join(rootDir, 'package.json')) && hasNpmLockfileDisabled(rootDir)) {
    return true;
  }

  return false;
}

/**
 * npm 12 blocks dependency install scripts by default and still exits 0, so the only reliable
 * signal is to ask npm directly. `npm install-scripts ls` lists every package whose scripts are
 * still awaiting a decision, and does not exist before npm 12, where the command exits non-zero
 * and `getCommandOutput` hands back null.
 *
 * Pass `packageManager` when the caller already knows which one ran the install; otherwise it is
 * inferred from the project.
 */
export async function getBlockedInstallScripts(
  rootDir: string,
  packageManager?: string,
): Promise<BlockedInstallScript[] | null> {
  if (packageManager === undefined) {
    logAmbiguousLockfiles(rootDir);
  }

  const isNpm = packageManager === undefined ? await isNpmProject(rootDir) : packageManager.toLowerCase() === 'npm';

  if (!isNpm) {
    return [];
  }

  const npmVersionOutput = await getCommandOutput('npm', ['--version'], { cwd: rootDir });
  if (npmVersionOutput === null) {
    output.write(
      `${c.strong('Blocked install scripts:')}\n\n` +
        `  Could not determine the npm version, so blocked install scripts were not checked.\n\n`,
    );
    return null;
  }

  const npmMajor = parseInt(npmVersionOutput.split('.')[0], 10);
  if (!Number.isFinite(npmMajor) || npmMajor < 12) {
    return [];
  }

  const commandOutput = await getCommandOutput('npm', ['install-scripts', 'ls', '--json', '--all=false'], {
    cwd: rootDir,
  });

  if (commandOutput === null) {
    output.write(
      `${c.strong('Blocked install scripts:')}\n\n` +
        `  Could not query npm for blocked install scripts. ` +
        `If ${c.input('all=true')} is set in ${c.input('.npmrc')}, run ${c.input('npm install-scripts ls --all=false')} manually.\n\n`,
    );
    return null;
  }

  return parseBlockedInstallScripts(commandOutput);
}

export function parseBlockedInstallScripts(commandOutput: string | null): BlockedInstallScript[] {
  if (!commandOutput) {
    return [];
  }

  let parsed: any;
  try {
    parsed = JSON.parse(commandOutput);
  } catch (e) {
    return [];
  }

  if (!Array.isArray(parsed?.allowScripts)) {
    return [];
  }

  const blocked: BlockedInstallScript[] = [];

  for (const entry of parsed.allowScripts) {
    const name = entry?.name;
    if (typeof name !== 'string' || !Array.isArray(entry.changes)) {
      continue;
    }

    for (const change of entry.changes) {
      if (change?.change !== 'pending' || typeof change.key !== 'string') {
        continue;
      }

      blocked.push({
        name,
        version: change.key.startsWith(`${name}@`) ? change.key.slice(name.length + 1) : change.key,
      });
    }
  }

  return blocked;
}

/**
 * npm 12 denies install scripts by default, so a typical project has pending entries for packages
 * like esbuild or sharp that a Capacitor migration has no bearing on. Only Capacitor's own blocked
 * scripts say anything about whether the migration finished.
 */
export function hasBlockedCapacitorScripts(blocked: BlockedInstallScript[]): boolean {
  return blocked.some(({ name }) => name.startsWith('@capacitor-plus/') || name.startsWith('@capacitor/'));
}

export function logBlockedInstallScripts(blocked: BlockedInstallScript[]): void {
  if (blocked.length === 0) {
    return;
  }

  const names = [...new Set(blocked.map(({ name }) => name))];
  const packages = blocked.map(({ name, version }) => `    ${c.strong(`${name}@${version}`)}\n`).join('');
  const approvals = names.map((name) => `    ${c.input(`npm install-scripts approve ${name}`)}\n`).join('');

  output.write(
    `${c.strong('Blocked Install Scripts:')}\n\n` +
      `  npm blocked install scripts for ${names.length === 1 ? '1 package' : `${names.length} packages`}. ` +
      `Features that rely on them may not work.\n\n` +
      packages +
      `\n  To allow them, run:\n\n` +
      approvals +
      `    ${c.input('npm rebuild')}\n\n` +
      `  ${c.weak('Approvals are pinned to an exact version, so repeat this after upgrading the package.')}\n\n`,
  );
}
