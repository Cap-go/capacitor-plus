#!/usr/bin/env bash
set -euo pipefail

TRUSTED_PLUS_REF="${TRUSTED_PLUS_REF:-plus}"

PRESERVE_MJS="$(mktemp --suffix=.mjs)"
trap 'rm -f "$PRESERVE_MJS"' EXIT

git show "${TRUSTED_PLUS_REF}:scripts/preserve-fork-changelog.mjs" > "$PRESERVE_MJS"

CHANGELOG_PATHS=(
  CHANGELOG.md
  cli/CHANGELOG.md
  core/CHANGELOG.md
  ios/CHANGELOG.md
  android/CHANGELOG.md
)

changed=0
for changelog_path in "${CHANGELOG_PATHS[@]}"; do
  if [ ! -f "$changelog_path" ]; then
    continue
  fi

  plus_changelog="$(mktemp --suffix=-plus-changelog.md)"
  git show "${TRUSTED_PLUS_REF}:${changelog_path}" > "$plus_changelog"
  node "$PRESERVE_MJS" "$changelog_path" "$plus_changelog"
  rm -f "$plus_changelog"

  if ! git diff --quiet "$changelog_path"; then
    git add "$changelog_path"
    changed=1
  fi
done

if [ "$changed" -eq 1 ]; then
  git commit -m "chore: preserve Capacitor+ changelog history after upstream sync"
fi
