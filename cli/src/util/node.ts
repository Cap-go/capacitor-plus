import { existsSync } from 'fs';
import { readFileSync } from 'fs-extra';
import { resolve } from 'path';
import type typescript from 'typescript';
import { pathToFileURL } from 'url';

interface NodeModuleWithCompile extends NodeJS.Module {
  _compile?(code: string, filename: string): any;
}

/**
 * TypeScript 7 dropped the classic compiler API (transpileModule, ModuleKind, etc.) from its
 * default export -- `require('typescript')` now only exposes `version`/`versionMajorMinor`.
 * Detect that case so we can fall back to a loading strategy that doesn't depend on it.
 *
 * @see https://github.com/ionic-team/capacitor/issues/8531
 */
function hasClassicCompilerAPI(ts: typeof typescript): boolean {
  return typeof ts.transpileModule === 'function';
}

/**
 * A plain `import()` here gets downleveled to a `require()` call by tsc when compiling to
 * CommonJS (our build target), which defeats the purpose -- we specifically need the real ESM
 * loader so Node's native TypeScript stripping kicks in. Constructing the import from a string
 * keeps tsc from touching it.
 */
const dynamicImport: (specifier: string) => Promise<any> = new Function('specifier', 'return import(specifier)') as any;

/**
 * @see https://github.com/ionic-team/stencil/blob/HEAD/src/compiler/sys/node-require.ts
 */
export const requireTS = async (ts: typeof typescript, p: string): Promise<unknown> => {
  const id = resolve(p);

  if (!hasClassicCompilerAPI(ts)) {
    // Node has its own built-in TypeScript syntax stripping (stable since Node 23.6, and
    // available behind --experimental-strip-types since Node 22.6), so we can load the file
    // directly via the native ESM loader instead of transpiling it ourselves.
    try {
      return await dynamicImport(pathToFileURL(id).href);
    } catch (e: any) {
      if (e?.code === 'ERR_UNKNOWN_FILE_EXTENSION') {
        throw new Error(
          `Your installed version of TypeScript (${ts.version}) no longer provides the compiler API Capacitor previously used to load .ts config files, ` +
            `and your Node.js runtime (${process.version}) doesn't support loading them natively either.\n` +
            'Upgrade to Node.js 22.6+ (running with --experimental-strip-types), or Node.js 23.6+, to continue using capacitor.config.ts.',
        );
      }
      throw e;
    }
  }

  delete require.cache[id];

  require.extensions['.ts'] = (module: NodeModuleWithCompile, fileName: string) => {
    let sourceText = readFileSync(fileName, 'utf8');

    if (fileName.endsWith('.ts')) {
      const tsResults = ts.transpileModule(sourceText, {
        fileName,
        compilerOptions: {
          module: ts.ModuleKind.CommonJS,
          moduleResolution: ts.ModuleResolutionKind.NodeJs,
          esModuleInterop: true,
          strict: true,
          target: ts.ScriptTarget.ES2017,
        },
        reportDiagnostics: true,
      });
      sourceText = tsResults.outputText;
    } else {
      // quick hack to turn a modern es module
      // into and old school commonjs module
      sourceText = sourceText.replace(/export\s+\w+\s+(\w+)/gm, 'exports.$1');
    }

    module._compile?.(sourceText, fileName);
  };

  const m = require(id); // eslint-disable-line @typescript-eslint/no-var-requires

  delete require.extensions['.ts'];

  return m;
}

function loadWithCliBundledCompiler(id: string): unknown | null {
  const cliRoot = resolve(__dirname, '..', '..');
  let cliTsPath: string;
  try {
    cliTsPath = require.resolve('typescript', { paths: [cliRoot] });
  } catch {
    return null;
  }

  const cliTs = require(cliTsPath) as typeof typescript; // eslint-disable-line @typescript-eslint/no-var-requires

  if (!hasClassicCompilerAPI(cliTs)) {
    return null;
  }

  return loadWithClassicCompiler(cliTs, id);
}

export const requireTS = async (ts: typeof typescript, p: string): Promise<unknown> => {
  const id = resolve(p);

  if (!hasClassicCompilerAPI(ts)) {
    // Node has its own built-in TypeScript syntax stripping (stable since Node 23.6, and
    // available behind --experimental-strip-types since Node 22.6), so we can load the file
    // directly via the native ESM loader instead of transpiling it ourselves.
    try {
      return await dynamicImport(pathToFileURL(id).href);
    } catch (e: any) {
      if (e?.code === 'ERR_UNKNOWN_FILE_EXTENSION') {
        throw new Error(
          `Your installed version of TypeScript (${ts.version}) no longer provides the compiler API Capacitor previously used to load .ts config files, ` +
            `and your Node.js runtime (${process.version}) doesn't support loading them natively either.\n` +
            'Upgrade to Node.js 22.6+ (running with --experimental-strip-types), or Node.js 23.6+, to continue using capacitor.config.ts.',
        );
      }
      if (e?.code === 'ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX') {
        const compiled = loadWithCliBundledCompiler(id);
        if (compiled !== null) {
          return compiled;
        }
        throw new Error(
          `Your capacitor.config.ts uses TypeScript syntax that cannot be loaded with Node's native type stripping (${e.message}).\n` +
            'Use erasable TypeScript syntax in capacitor.config.ts, or install a TypeScript version that still exposes the compiler API.',
        );
      }
      throw e;
    }
  }

  return loadWithClassicCompiler(ts, id);
};

export function resolveNode(root: string, ...pathSegments: string[]): string | null {
  try {
    return require.resolve(pathSegments.join('/'), { paths: [root] });
  } catch (e) {
    const path = [root, 'node_modules', ...pathSegments].join('/');
    if (existsSync(path)) {
      return path;
    }
    return null;
  }
}
