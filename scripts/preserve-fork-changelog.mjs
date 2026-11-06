#!/usr/bin/env node
/**
 * After an upstream sync merge, re-insert Capacitor+ release sections from the plus branch
 * changelog so fork-specific history is not dropped by upstream-preferred conflict resolution.
 */

import { readFileSync, writeFileSync } from 'node:fs';

const FORK_SECTION_HEADER = /^#{1,2} \[.*\]\(https:\/\/github\.com\/Cap-go\/capacitor-plus\//;

function splitSections(content) {
  const lines = content.split('\n');
  const header = [];
  const sections = [];
  let current = null;
  let inHeader = true;

  for (const line of lines) {
    if (/^#{1,2} \[/.test(line)) {
      inHeader = false;
      if (current) {
        sections.push(current);
      }
      current = { header: line, body: [] };
      continue;
    }

    if (inHeader) {
      header.push(line);
    } else if (current) {
      current.body.push(line);
    }
  }

  if (current) {
    sections.push(current);
  }

  return { header: header.join('\n'), sections };
}

function sectionText(section) {
  return [section.header, ...section.body].join('\n').trimEnd();
}

function isForkSection(section) {
  return FORK_SECTION_HEADER.test(section.header);
}

const VERSION_HEADER = /^#{1,2} \[([^\]]+)\]/;
const RELEASE_DATE_SUFFIX = /\((\d{4}-\d{2}-\d{2})\)\s*$/;

function parseVersionLabel(versionLabel) {
  const cleaned = versionLabel.replace(/^v/i, '');
  const hyphenIndex = cleaned.indexOf('-');
  const base = hyphenIndex === -1 ? cleaned : cleaned.slice(0, hyphenIndex);
  const prerelease = hyphenIndex === -1 ? null : cleaned.slice(hyphenIndex + 1);

  return {
    version: base.split('.').map((part) => parseInt(part, 10) || 0),
    prerelease,
  };
}

function sectionSortKey(section) {
  const versionMatch = section.header.match(VERSION_HEADER);
  if (!versionMatch) {
    return { version: [0], prerelease: null, date: '0000-00-00' };
  }

  const dateMatch = section.header.match(RELEASE_DATE_SUFFIX);
  const { version, prerelease } = parseVersionLabel(versionMatch[1]);
  return {
    version,
    prerelease,
    date: dateMatch ? dateMatch[1] : '0000-00-00',
  };
}

function compareReleaseSections(a, b) {
  const left = sectionSortKey(a);
  const right = sectionSortKey(b);
  const maxLength = Math.max(left.version.length, right.version.length);

  for (let index = 0; index < maxLength; index += 1) {
    const leftPart = left.version[index] ?? 0;
    const rightPart = right.version[index] ?? 0;
    if (leftPart !== rightPart) {
      return rightPart - leftPart;
    }
  }

  if (left.prerelease !== right.prerelease) {
    if (left.prerelease === null) {
      return -1;
    }
    if (right.prerelease === null) {
      return 1;
    }
    return right.prerelease.localeCompare(left.prerelease, undefined, { numeric: true });
  }

  if (left.date !== right.date) {
    return right.date.localeCompare(left.date);
  }

  return 0;
}

function preserveForkChangelog(syncedPath, forkPath) {
  const synced = readFileSync(syncedPath, 'utf8');
  const fork = readFileSync(forkPath, 'utf8');

  const forkParsed = splitSections(fork);
  const syncedParsed = splitSections(synced);

  const sectionsByHeader = new Map();
  for (const section of syncedParsed.sections) {
    sectionsByHeader.set(section.header, section);
  }

  for (const section of forkParsed.sections.filter(isForkSection)) {
    if (!sectionsByHeader.has(section.header)) {
      sectionsByHeader.set(section.header, section);
    }
  }

  const mergedSections = [...sectionsByHeader.values()].sort(compareReleaseSections).map(sectionText);

  if (mergedSections.length === 0) {
    return synced;
  }

  const blocks = [syncedParsed.header.trimEnd(), ...mergedSections].filter((block) => block.length > 0);

  return `${blocks.join('\n\n')}\n`;
}

const syncedPath = process.argv[2];
const forkPath = process.argv[3];

if (!syncedPath || !forkPath) {
  console.error('Usage: preserve-fork-changelog.mjs <synced-changelog> <plus-branch-changelog>');
  process.exit(1);
}

writeFileSync(syncedPath, preserveForkChangelog(syncedPath, forkPath));
