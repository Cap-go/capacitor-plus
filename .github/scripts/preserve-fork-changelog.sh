#!/usr/bin/env bash
set -euo pipefail

TRUSTED_PLUS_REF="${TRUSTED_PLUS_REF:-plus}"

if [ ! -f CHANGELOG.md ]; then
  echo "CHANGELOG.md not found, skipping fork changelog preservation"
  exit 0
fi

PRESERVE_MJS="$(mktemp --suffix=.mjs)"
trap 'rm -f "$PRESERVE_MJS" /tmp/plus-changelog.md' EXIT

git show "${TRUSTED_PLUS_REF}:CHANGELOG.md" > /tmp/plus-changelog.md
git show "${TRUSTED_PLUS_REF}:scripts/preserve-fork-changelog.mjs" > "$PRESERVE_MJS"
node "$PRESERVE_MJS" CHANGELOG.md /tmp/plus-changelog.md

if ! git diff --quiet CHANGELOG.md; then
  git add CHANGELOG.md
  git commit -m "chore: preserve Capacitor+ changelog history after upstream sync"
fi
