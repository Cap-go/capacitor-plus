#!/usr/bin/env node
/**
 * Guards against App Store guideline 2.5.2 patterns (private API swizzling / unsafe dynamic dispatch)
 * in Capacitor iOS core sources. Bridge/plugin registration files are allowlisted.
 */
import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const iosCapacitorDir = path.join(root, 'ios/Capacitor/Capacitor');

const allowlist = new Set(['CAPPluginMethod.m', 'CapacitorBridge.swift']);

const forbiddenPatterns = [
  { name: 'method_exchangeImplementations', regex: /method_exchangeImplementations/ },
  { name: 'class_replaceMethod', regex: /class_replaceMethod/ },
  { name: 'method_setImplementation', regex: /method_setImplementation/ },
  { name: 'sel_getUid private selector', regex: /sel_getUid\s*\(\s*"_/ },
  { name: 'UIStatusBarManager handleTapAction swizzle', regex: /handleTapAction:/ },
  { name: 'WKContentView private class', regex: /NSClassFromString\s*\(\s*["']WK["']\s*\+\s*["']ContentView["']\)/ },
  {
    name: 'NSSelectorFromString shouldOverrideLoad',
    regex: /NSSelectorFromString\s*\(\s*["']shouldOverrideLoad:/,
  },
  {
    name: 'NSSelectorFromString auth challenge',
    regex: /NSSelectorFromString\s*\(\s*["']handleWKWebViewURLAuthenticationChallenge:/,
  },
  { name: 'perform selector SSL HTTP', regex: /\.perform\s*\(\s*#selector/ },
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
  const base = path.basename(file);
  if (allowlist.has(base)) {
    continue;
  }
  const content = await readFile(file, 'utf8');
  const rel = path.relative(root, file);
  for (const pattern of forbiddenPatterns) {
    if (pattern.regex.test(content)) {
      violations.push(`${rel}: forbidden ${pattern.name}`);
    }
  }
}

if (violations.length > 0) {
  console.error('iOS dynamic dispatch check failed:\n' + violations.map((v) => `  - ${v}`).join('\n'));
  process.exit(1);
}

console.log(`iOS dynamic dispatch check passed (${files.length} files scanned).`);
