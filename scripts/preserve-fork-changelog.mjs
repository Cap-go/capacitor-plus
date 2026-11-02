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

function preserveForkChangelog(syncedPath, forkPath) {
  const synced = readFileSync(syncedPath, 'utf8');
  const fork = readFileSync(forkPath, 'utf8');

  const forkParsed = splitSections(fork);
  const syncedParsed = splitSections(synced);

  const forkSections = forkParsed.sections.filter(isForkSection).map(sectionText);
  const upstreamSections = syncedParsed.sections.filter((section) => !isForkSection(section)).map(sectionText);

  if (forkSections.length === 0) {
    return synced;
  }

  const blocks = [syncedParsed.header.trimEnd(), ...forkSections, ...upstreamSections].filter(
    (block) => block.length > 0,
  );

  return `${blocks.join('\n\n')}\n`;
}

const syncedPath = process.argv[2];
const forkPath = process.argv[3];

if (!syncedPath || !forkPath) {
  console.error('Usage: preserve-fork-changelog.mjs <synced-changelog> <plus-branch-changelog>');
  process.exit(1);
}

writeFileSync(syncedPath, preserveForkChangelog(syncedPath, forkPath));
