#!/usr/bin/env bash
# Tests for the Capacitor+ upstream sync helpers.
# These lock in the rule: port an upstream PR by cherry-picking its
# own commits, never by merging the upstream PR branch.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=sync-gh-helpers.sh
source "${ROOT}/sync-gh-helpers.sh"

failures=0
passes=0

assert_file_equals() {
  local path="$1"
  local expected="$2"
  local actual
  actual=$(cat "$path"; printf x)
  actual=${actual%x}
  if [ "$actual" != "$expected" ]; then
    echo "  expected ${path} ($(printf '%s' "$expected" | wc -c) bytes) to be:"
    printf '%s' "$expected" | cat -A
    echo
    echo "  actual ($(printf '%s' "$actual" | wc -c) bytes):"
    printf '%s' "$actual" | cat -A
    echo
    return 1
  fi
  return 0
}

init_git_repo() {
  local dir="$1"
  rm -rf "$dir"
  mkdir -p "$dir"
  git -C "$dir" init -b main >/dev/null
  git -C "$dir" config user.email "sync-test@capgo.app"
  git -C "$dir" config user.name "Sync Helper Test"
}

# Shared fixture:
#   main starts with shared.txt=v1 and target.txt=original
#   plus customizes shared.txt to plus-custom and adds plus-only.txt
#   main then moves to shared.txt=v2 (conflicts with plus) and adds extra-upstream.txt
#   an upstream PR based on that newer main changes only target.txt
setup_divergence_fixture() {
  local work="$1"
  local upstream="${work}/upstream"
  local plus="${work}/plus"

  init_git_repo "$upstream"
  printf 'v1\n' > "${upstream}/shared.txt"
  printf 'original\n' > "${upstream}/target.txt"
  git -C "$upstream" add shared.txt target.txt
  git -C "$upstream" commit -m "initial upstream" >/dev/null

  rm -rf "$plus"
  git clone "$upstream" "$plus" >/dev/null 2>&1
  git -C "$plus" config user.email "sync-test@capgo.app"
  git -C "$plus" config user.name "Sync Helper Test"
  git -C "$plus" checkout -b plus >/dev/null 2>&1
  printf 'plus-custom\n' > "${plus}/shared.txt"
  printf 'capacitor-plus-only\n' > "${plus}/plus-only.txt"
  git -C "$plus" add shared.txt plus-only.txt
  git -C "$plus" commit -m "plus customizations" >/dev/null

  printf 'v2\n' > "${upstream}/shared.txt"
  printf 'from-upstream-main\n' > "${upstream}/extra-upstream.txt"
  git -C "$upstream" add shared.txt extra-upstream.txt
  git -C "$upstream" commit -m "upstream main moves shared.txt to v2" >/dev/null

  git -C "$upstream" checkout -b pr-branch >/dev/null 2>&1
  printf 'pr-change\n' > "${upstream}/target.txt"
  git -C "$upstream" add target.txt
  git -C "$upstream" commit -m "upstream PR changes target.txt" >/dev/null
  UPSTREAM_PR_SHA=$(git -C "$upstream" rev-parse HEAD)
  git -C "$upstream" checkout main >/dev/null 2>&1

  git -C "$plus" remote add upstream "$upstream"
  git -C "$plus" fetch upstream >/dev/null 2>&1
  git -C "$plus" branch upstream-main upstream/main >/dev/null
  git -C "$plus" branch upstream-pr-1 upstream/pr-branch >/dev/null
}

test_old_merge_wipes_plus_customization() {
  local work
  work=$(mktemp -d)
  setup_divergence_fixture "$work"
  local plus="${work}/plus"

  git -C "$plus" checkout -b old-merge plus >/dev/null 2>&1
  # This is the old generator: merge the whole upstream PR branch and
  # prefer upstream on conflicts.
  git -C "$plus" merge upstream-pr-1 -X theirs --no-edit -m "old merge" >/dev/null 2>&1 || {
    echo "  old-style merge failed unexpectedly"
    rm -rf "$work"
    return 1
  }

  if ! assert_file_equals "${plus}/shared.txt" $'v2\n'; then
    echo "  expected the old merge to overwrite plus-custom with upstream v2"
    rm -rf "$work"
    return 1
  fi
  if ! assert_file_equals "${plus}/target.txt" $'pr-change\n'; then
    rm -rf "$work"
    return 1
  fi

  rm -rf "$work"
  return 0
}

test_cherry_pick_keeps_plus_and_applies_pr() {
  local work
  work=$(mktemp -d)
  setup_divergence_fixture "$work"
  local plus="${work}/plus"

  git -C "$plus" checkout -b sync-pr plus >/dev/null 2>&1
  (
    cd "$plus"
    # shellcheck disable=SC1091
    source "${ROOT}/sync-gh-helpers.sh"
    cherry_pick_shas "$UPSTREAM_PR_SHA"
  )

  if ! assert_file_equals "${plus}/shared.txt" $'plus-custom\n'; then
    echo "  cherry-pick must not overwrite the plus customization"
    rm -rf "$work"
    return 1
  fi
  if ! assert_file_equals "${plus}/plus-only.txt" $'capacitor-plus-only\n'; then
    rm -rf "$work"
    return 1
  fi
  if ! assert_file_equals "${plus}/target.txt" $'pr-change\n'; then
    echo "  cherry-pick must apply the upstream PR file"
    rm -rf "$work"
    return 1
  fi
  if [ -f "${plus}/extra-upstream.txt" ]; then
    echo "  cherry-pick must not pull unrelated upstream main files"
    rm -rf "$work"
    return 1
  fi

  local changed
  changed=$(git -C "$plus" diff --name-only plus...HEAD)
  if [ "$changed" != "target.txt" ]; then
    echo "  expected only target.txt to change, got:"
    echo "    ${changed}"
    rm -rf "$work"
    return 1
  fi

  rm -rf "$work"
  return 0
}

test_cherry_pick_theirs_prefers_pr_hunk_keeps_plus_hunk() {
  local work
  work=$(mktemp -d)
  init_git_repo "${work}/repo"
  local repo="${work}/repo"

  printf 'header\nmiddle\nfooter\n' > "${repo}/shared.txt"
  git -C "$repo" add shared.txt
  git -C "$repo" commit -m "base" >/dev/null

  git -C "$repo" checkout -b plus >/dev/null 2>&1
  printf 'plus-header\nmiddle\nfooter\n' > "${repo}/shared.txt"
  git -C "$repo" add shared.txt
  git -C "$repo" commit -m "plus header" >/dev/null

  git -C "$repo" checkout main >/dev/null 2>&1
  printf 'header\nmiddle\npr-footer\n' > "${repo}/shared.txt"
  git -C "$repo" add shared.txt
  git -C "$repo" commit -m "pr footer" >/dev/null
  local pr_sha
  pr_sha=$(git -C "$repo" rev-parse HEAD)

  git -C "$repo" checkout plus >/dev/null 2>&1
  (
    cd "$repo"
    source "${ROOT}/sync-gh-helpers.sh"
    cherry_pick_shas "$pr_sha"
  )

  if ! assert_file_equals "${repo}/shared.txt" $'plus-header\nmiddle\npr-footer\n'; then
    echo "  non-overlapping hunks should combine plus header with PR footer"
    rm -rf "$work"
    return 1
  fi

  rm -rf "$work"
  return 0
}

test_cherry_pick_theirs_resolves_same_hunk_conflict() {
  local work
  work=$(mktemp -d)
  init_git_repo "${work}/repo"
  local repo="${work}/repo"

  printf 'same-line\n' > "${repo}/shared.txt"
  git -C "$repo" add shared.txt
  git -C "$repo" commit -m "base" >/dev/null

  git -C "$repo" checkout -b plus >/dev/null 2>&1
  printf 'plus-line\n' > "${repo}/shared.txt"
  git -C "$repo" add shared.txt
  git -C "$repo" commit -m "plus line" >/dev/null

  git -C "$repo" checkout main >/dev/null 2>&1
  printf 'pr-line\n' > "${repo}/shared.txt"
  git -C "$repo" add shared.txt
  git -C "$repo" commit -m "pr line" >/dev/null
  local pr_sha
  pr_sha=$(git -C "$repo" rev-parse HEAD)

  git -C "$repo" checkout plus >/dev/null 2>&1
  (
    cd "$repo"
    source "${ROOT}/sync-gh-helpers.sh"
    if cherry_pick_shas "$pr_sha"; then
      echo "  expected a conflict on the same hunk without --theirs"
      rm -rf "$work"
      return 1
    fi
    abort_in_progress_cherry_pick
    cherry_pick_shas --theirs "$pr_sha"
  )

  if ! assert_file_equals "${repo}/shared.txt" $'pr-line\n'; then
    echo "  --theirs should keep the upstream PR hunk on a same-line conflict"
    rm -rf "$work"
    return 1
  fi

  rm -rf "$work"
  return 0
}

test_already_applied_detects_equivalent_patch() {
  local work
  work=$(mktemp -d)
  setup_divergence_fixture "$work"
  local plus="${work}/plus"

  git -C "$plus" checkout -b sync-pr plus >/dev/null 2>&1
  if ! (
    cd "$plus"
    source "${ROOT}/sync-gh-helpers.sh"
    cherry_pick_shas "$UPSTREAM_PR_SHA"
    upstream_pr_already_applied HEAD upstream-pr-1 upstream-main
  ); then
    echo "  expected the cherry-picked patch to count as already applied"
    rm -rf "$work"
    return 1
  fi
  if (
    cd "$plus"
    source "${ROOT}/sync-gh-helpers.sh"
    upstream_pr_already_applied plus upstream-pr-1 upstream-main
  ); then
    echo "  plus itself should not already contain the PR patch"
    rm -rf "$work"
    return 1
  fi

  rm -rf "$work"
  return 0
}

test_merge_plus_preserving_keeps_plus_and_takes_new_files() {
  local work
  work=$(mktemp -d)
  setup_divergence_fixture "$work"
  local plus="${work}/plus"

  git -C "$plus" checkout plus >/dev/null 2>&1
  (
    cd "$plus"
    source "${ROOT}/sync-gh-helpers.sh"
    merge_plus_preserving "chore: sync plus with upstream main" upstream-main
    if [ "$MERGE_PLUS_PRESERVING_RESOLUTION" != "ours" ]; then
      echo "  expected ours resolution, got ${MERGE_PLUS_PRESERVING_RESOLUTION}"
      rm -rf "$work"
      return 1
    fi
  )

  if ! assert_file_equals "${plus}/shared.txt" $'plus-custom\n'; then
    echo "  plus-preserving merge must keep plus-custom"
    rm -rf "$work"
    return 1
  fi
  if ! assert_file_equals "${plus}/plus-only.txt" $'capacitor-plus-only\n'; then
    rm -rf "$work"
    return 1
  fi
  if ! assert_file_equals "${plus}/extra-upstream.txt" $'from-upstream-main\n'; then
    echo "  plus-preserving merge must still take non-conflicting upstream files"
    rm -rf "$work"
    return 1
  fi
  if ! assert_file_equals "${plus}/target.txt" $'original\n'; then
    echo "  merging main should not apply the unrelated PR change"
    rm -rf "$work"
    return 1
  fi

  rm -rf "$work"
  return 0
}

run_test() {
  local name="$1"
  shift
  echo "TEST ${name}"
  if "$@"; then
    echo "PASS ${name}"
    passes=$((passes + 1))
  else
    echo "FAIL ${name}"
    failures=$((failures + 1))
  fi
}


test_git_wrapper_intercepts_upstream_pr_merge() {
  local work
  work=$(mktemp -d)
  setup_divergence_fixture "$work"
  local plus="${work}/plus"

  git -C "$plus" checkout -b sync-pr plus >/dev/null 2>&1
  (
    cd "$plus"
    source "${ROOT}/sync-gh-helpers.sh"
    list_upstream_pr_commit_shas() { return 1; }
    # Same invocation the scheduled workflow uses.
    git merge upstream-pr-1 --no-edit -m "chore: sync upstream PR #1 from @tester"
  )

  if ! assert_file_equals "${plus}/shared.txt" $'plus-custom\n'; then
    echo "  wrapper must not wipe plus-custom"
    rm -rf "$work"
    return 1
  fi
  if ! assert_file_equals "${plus}/plus-only.txt" $'capacitor-plus-only\n'; then
    rm -rf "$work"
    return 1
  fi
  if ! assert_file_equals "${plus}/target.txt" $'pr-change\n'; then
    echo "  wrapper must still apply the upstream PR change"
    rm -rf "$work"
    return 1
  fi
  if [ -f "${plus}/extra-upstream.txt" ]; then
    echo "  wrapper must not merge unrelated upstream main files"
    rm -rf "$work"
    return 1
  fi

  local changed
  changed=$(git -C "$plus" diff --name-only plus...HEAD)
  if [ "$changed" != "target.txt" ]; then
    echo "  expected only target.txt to change, got:"
    echo "    ${changed}"
    rm -rf "$work"
    return 1
  fi

  rm -rf "$work"
  return 0
}

test_git_wrapper_treats_cherry_pick_as_applied() {
  local work
  work=$(mktemp -d)
  setup_divergence_fixture "$work"
  local plus="${work}/plus"

  git -C "$plus" checkout -b sync-pr plus >/dev/null 2>&1
  if ! (
    cd "$plus"
    source "${ROOT}/sync-gh-helpers.sh"
    list_upstream_pr_commit_shas() { return 1; }
    git merge upstream-pr-1 --no-edit -m "chore: sync upstream PR #1"
    tip=$(command git rev-parse upstream-pr-1)
    git merge-base --is-ancestor "$tip" HEAD
  ); then
    echo "  expected cherry-pick trailer to satisfy the up-to-date ancestor check"
    rm -rf "$work"
    return 1
  fi

  rm -rf "$work"
  return 0
}

test_merge_upstream_preferred_on_plus_keeps_customization() {
  local work
  work=$(mktemp -d)
  setup_divergence_fixture "$work"
  local plus="${work}/plus"

  git -C "$plus" checkout -b sync/plus-upstream-test plus >/dev/null 2>&1
  (
    cd "$plus"
    source "${ROOT}/sync-gh-helpers.sh"
    merge_upstream_preferred "chore: sync plus with upstream main (upstream-preferred conflicts)"
  )

  if ! assert_file_equals "${plus}/shared.txt" $'plus-custom\n'; then
    echo "  merge_upstream_preferred on a plus sync branch must keep plus-custom"
    rm -rf "$work"
    return 1
  fi
  if ! assert_file_equals "${plus}/extra-upstream.txt" $'from-upstream-main\n'; then
    echo "  plus-preserving fallback must still take new upstream files"
    rm -rf "$work"
    return 1
  fi

  rm -rf "$work"
  return 0
}


test_git_wrapper_plain_merge_leaves_conflicts_for_theirs_retry() {
  local work
  work=$(mktemp -d)
  init_git_repo "${work}/repo"
  local repo="${work}/repo"

  printf 'same-line\n' > "${repo}/shared.txt"
  git -C "$repo" add shared.txt
  git -C "$repo" commit -m "base" >/dev/null

  git -C "$repo" checkout -b plus >/dev/null 2>&1
  printf 'plus-line\n' > "${repo}/shared.txt"
  git -C "$repo" add shared.txt
  git -C "$repo" commit -m "plus line" >/dev/null

  git -C "$repo" checkout -b pr-branch main >/dev/null 2>&1
  printf 'pr-line\n' > "${repo}/shared.txt"
  git -C "$repo" add shared.txt
  git -C "$repo" commit -m "pr line" >/dev/null

  git -C "$repo" checkout plus >/dev/null 2>&1
  git -C "$repo" branch upstream-pr-1 pr-branch >/dev/null
  git -C "$repo" branch upstream-main main >/dev/null

  (
    cd "$repo"
    source "${ROOT}/sync-gh-helpers.sh"
    list_upstream_pr_commit_shas() { return 1; }
    if git merge upstream-pr-1 --no-edit -m "chore: sync upstream PR #1"; then
      echo "  plain merge of a conflicting upstream PR should fail so the workflow can take its conflict branch"
      rm -rf "$work"
      return 1
    fi
    if ! git merge upstream-pr-1 -X theirs --no-edit -m "chore: sync upstream PR #1 (upstream-preferred conflicts)"; then
      echo "  -X theirs should apply the upstream PR hunk"
      rm -rf "$work"
      return 1
    fi
  ) || {
    rm -rf "$work"
    return 1
  }

  if ! assert_file_equals "${repo}/shared.txt" $'pr-line\n'; then
    echo "  -X theirs should keep the upstream PR hunk on a same-line conflict"
    rm -rf "$work"
    return 1
  fi

  rm -rf "$work"
  return 0
}

run_test old_merge_wipes_plus_customization test_old_merge_wipes_plus_customization
run_test git_wrapper_plain_merge_leaves_conflicts_for_theirs_retry test_git_wrapper_plain_merge_leaves_conflicts_for_theirs_retry
run_test cherry_pick_keeps_plus_and_applies_pr test_cherry_pick_keeps_plus_and_applies_pr
run_test cherry_pick_combines_nonoverlapping_hunks test_cherry_pick_theirs_prefers_pr_hunk_keeps_plus_hunk
run_test cherry_pick_theirs_resolves_same_hunk_conflict test_cherry_pick_theirs_resolves_same_hunk_conflict
run_test already_applied_detects_equivalent_patch test_already_applied_detects_equivalent_patch
run_test merge_plus_preserving_keeps_plus_and_takes_new_files test_merge_plus_preserving_keeps_plus_and_takes_new_files
run_test git_wrapper_intercepts_upstream_pr_merge test_git_wrapper_intercepts_upstream_pr_merge
run_test git_wrapper_treats_cherry_pick_as_applied test_git_wrapper_treats_cherry_pick_as_applied
run_test merge_upstream_preferred_on_plus_keeps_customization test_merge_upstream_preferred_on_plus_keeps_customization

echo ""
echo "Passed: ${passes}  Failed: ${failures}"
if [ "$failures" -ne 0 ]; then
  exit 1
fi
