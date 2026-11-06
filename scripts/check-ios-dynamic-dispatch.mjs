#!/usr/bin/env node
/**
 * Flags runtime-built private API names (App Store 2.5.2 dynamic dispatch patterns).
 * Private API usage with compile-time static names is allowed when annotated.
 */
import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const iosCapacitorDir = path.join(root, 'ios/Capacitor/Capacitor');

const forbiddenPatterns = [
  {
    name: 'WKContentView name built at runtime',
    regex: /["']WK["']\s*\+\s*["']ContentView["']/,
  },
  {
    name: 'sel_getUid private selector',
    regex: /sel_getUid\s*\(\s*"/,
  },
  {
    name: 'NSSelectorFromString for plugin hooks',
    regex: /NSSelectorFromString\s*\(\s*["']shouldOverrideLoad:/,
  },
  {
    name: 'NSSelectorFromString for auth challenge hook',
    regex: /NSSelectorFromString\s*\(\s*["']handleWKWebViewURLAuthenticationChallenge:/,
  },
  {
    name: 'inline NSClassFromString SSL pinning class',
    regex: /NSClassFromString\s*\(\s*["']SSLPinningHttpRequestHandlerClass["']\s*\)/,
  },
  {
    name: 'inline NSSelectorFromString status bar handleTapAction',
    regex: /NSSelectorFromString\s*\(\s*["']handleTapAction:/,
  },
];

async function walk(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...(await walk(full)));
    } else if (/\.(m|mm|swift)$/.test(entry.name)) {
      files.push(full);
    }
  }
  return files;
}

const files = await walk(iosCapacitorDir);
const violations = [];

for (const file of files) {
  const content = await readFile(file, 'utf8');
  const rel = path.relative(root, file);
  for (const pattern of forbiddenPatterns) {
    if (pattern.regex.test(content)) {
      violations.push(`${rel}: ${pattern.name}`);
    }
  }
}

if (violations.length > 0) {
  console.error('iOS static private API check failed:\n' + violations.map((v) => `  - ${v}`).join('\n'));
  process.exit(1);
}

console.log(`iOS static private API check passed (${files.length} files scanned).`);
