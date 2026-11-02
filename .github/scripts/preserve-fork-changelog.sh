#!/usr/bin/env bash
set -euo pipefail

if [ ! -f CHANGELOG.md ]; then
  echo "CHANGELOG.md not found, skipping fork changelog preservation"
  exit 0
fi

git show plus:CHANGELOG.md > /tmp/plus-changelog.md
git show plus:scripts/preserve-fork-changelog.mjs > /tmp/preserve-fork-changelog.mjs
node /tmp/preserve-fork-changelog.mjs CHANGELOG.md /tmp/plus-changelog.md

if ! git diff --quiet CHANGELOG.md; then
  git add CHANGELOG.md
  git commit -m "chore: preserve Capacitor+ changelog history after upstream sync"
fi
