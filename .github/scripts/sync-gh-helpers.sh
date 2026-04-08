#!/usr/bin/env bash

set -euo pipefail

ensure_repo_label() {
  local repo="$1"
  local name="$2"
  local color="$3"
  local description="$4"

  if gh api "repos/${repo}/labels/${name}" >/dev/null 2>&1; then
    return 0
  fi

  gh label create "$name" \
    --repo "$repo" \
    --color "$color" \
    --description "$description" >/dev/null 2>&1 || {
    echo "Warning: could not create label '${name}'"
    return 1
  }
}

ensure_sync_labels() {
  local repo="$1"

  ensure_repo_label "$repo" upstream-sync 1d76db "Automated sync from upstream changes" || true
  ensure_repo_label "$repo" automated 0e8a16 "Fully automated workflow-managed change" || true
  ensure_repo_label "$repo" needs-attention b60205 "Needs human follow-up" || true
  ensure_repo_label "$repo" merge-conflict d93f0b "Merge conflict detected during automation" || true
  ensure_repo_label "$repo" security b60205 "Potential security concern flagged by automation" || true
  ensure_repo_label "$repo" priority-critical b60205 "Critical priority follow-up" || true
  ensure_repo_label "$repo" suspicious 5319e7 "Suspicious change pattern detected" || true
  ensure_repo_label "$repo" breaking-change fbca04 "Potential breaking change detected" || true
  ensure_repo_label "$repo" priority-high d4c5f9 "High-priority follow-up" || true
  ensure_repo_label "$repo" stability f9d0c4 "Potential stability concern detected" || true
  ensure_repo_label "$repo" data-privacy 0052cc "Potential data or privacy concern detected" || true
}

repo_has_issues() {
  local repo="$1"
  gh api "repos/${repo}" --jq '.has_issues' 2>/dev/null || echo "false"
}

create_pr_and_capture_number() {
  local repo="$1"
  local base="$2"
  local head="$3"
  local title="$4"
  local body="$5"

  gh pr create \
    --repo "$repo" \
    --base "$base" \
    --head "$head" \
    --title "$title" \
    --body "$body" >/dev/null

  gh pr list \
    --repo "$repo" \
    --state open \
    --base "$base" \
    --head "$head" \
    --json number \
    -q '.[0].number'
}

add_labels_to_pr() {
  local repo="$1"
  local pr_number="$2"
  shift 2

  if [ "$#" -eq 0 ]; then
    return 0
  fi

  local csv
  csv=$(printf '%s,' "$@")
  csv=${csv%,}

  gh pr edit "$pr_number" --repo "$repo" --add-label "$csv" >/dev/null 2>&1 || {
    echo "Warning: could not add labels '${csv}' to PR #${pr_number}"
    return 1
  }
}
