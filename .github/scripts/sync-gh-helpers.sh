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

create_or_update_conflict_issue() {
  local repo="$1"
  local title="$2"
  local body="$3"
  local search_text="Upstream sync requires manual conflict resolution in:title"

  if [ "$(repo_has_issues "$repo")" != "true" ]; then
    return 1
  fi

  local existing_issue
  existing_issue=$(
    gh issue list \
      --repo "$repo" \
      --state open \
      --search "$search_text" \
      --json number \
      -q '.[0].number' 2>/dev/null || true
  )

  if [ -n "$existing_issue" ]; then
    gh issue comment "$existing_issue" --repo "$repo" --body "$body" >/dev/null 2>&1 || return 1
    echo "$existing_issue"
    return 0
  fi

  gh issue create \
    --repo "$repo" \
    --title "$title" \
    --body "$body" \
    --label upstream-sync \
    --label merge-conflict \
    --label needs-attention >/dev/null 2>&1 || return 1

  gh issue list \
    --repo "$repo" \
    --state open \
    --search "$search_text" \
    --json number \
    -q '.[0].number'
}

# For the main branch (an upstream mirror) this prefers upstream on conflicts.
# If the current branch is plus or a plus sync branch, it delegates to
# merge_plus_preserving so Capacitor+ files are not overwritten.
merge_upstream_preferred() {
  local commit_message="$1"
  local branch
  branch=$(command git rev-parse --abbrev-ref HEAD)
  case "$branch" in
    plus|sync/plus-upstream-*|sync/upstream-main-*)
      echo "Refusing upstream-preferred merge on ${branch}; using plus-preserving merge instead"
      merge_plus_preserving "$commit_message" upstream/main
      return $?
      ;;
  esac

  if git merge upstream/main -X theirs --no-edit -m "$commit_message"; then
    return 0
  fi

  local unmerged
  unmerged=$(git diff --name-only --diff-filter=U)
  if [ -z "$unmerged" ]; then
    return 1
  fi

  local file
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    # -X theirs does not resolve modify/delete conflicts; prefer upstream version.
    if git checkout --theirs -- "$file" 2>/dev/null; then
      git add "$file"
    elif git rm -f "$file" 2>/dev/null; then
      :
    else
      return 1
    fi
  done <<< "$unmerged"

  if [ -n "$(git diff --name-only --diff-filter=U)" ]; then
    return 1
  fi

  if command git rev-parse -q --verify MERGE_HEAD >/dev/null; then
    git commit --no-edit || git commit -m "$commit_message"
    return 0
  fi

  return 1
}

abort_in_progress_cherry_pick() {
  # Use git-dir, not .git/..., because worktrees have .git as a file.
  local git_dir
  git_dir=$(command git rev-parse --git-dir 2>/dev/null || echo .git)
  command git cherry-pick --abort >/dev/null 2>&1 || true
  if [ -f "${git_dir}/CHERRY_PICK_HEAD" ] || [ -d "${git_dir}/sequencer" ]; then
    command git reset --hard HEAD >/dev/null 2>&1 || true
  fi
  if [ -n "$(command git diff --name-only --diff-filter=U 2>/dev/null)" ]; then
    command git reset --hard HEAD >/dev/null 2>&1 || true
  fi
}

# Cherry-pick one commit. Treat an already-applied (empty) pick as success.
# Extra git cherry-pick args may follow the sha (for example -X theirs).
cherry_pick_one_sha() {
  local sha="$1"
  shift

  local output
  local rc=0
  output=$(git cherry-pick -x "$@" "$sha" 2>&1) || rc=$?
  printf '%s\n' "$output"

  if [ "$rc" -eq 0 ]; then
    return 0
  fi

  if printf '%s\n' "$output" | grep -qiE 'previous cherry-pick is now empty|nothing to commit'; then
    echo "Cherry-pick of ${sha} was empty (already applied), skipping"
    git cherry-pick --skip >/dev/null 2>&1 || git reset --hard HEAD >/dev/null 2>&1 || true
    return 0
  fi

  return 1
}

# usage: cherry_pick_shas [--theirs] sha1 [sha2 ...]
cherry_pick_shas() {
  local use_theirs=false
  if [ "${1:-}" = "--theirs" ]; then
    use_theirs=true
    shift
  fi

  if [ "$#" -eq 0 ]; then
    echo "No commits to cherry-pick"
    return 0
  fi

  local sha
  for sha in "$@"; do
    if [ "$use_theirs" = true ]; then
      if ! cherry_pick_one_sha "$sha" -X theirs; then
        return 1
      fi
    else
      if ! cherry_pick_one_sha "$sha"; then
        return 1
      fi
    fi
  done
  return 0
}

list_upstream_pr_commit_shas() {
  local upstream_repo="$1"
  local pr_number="$2"
  gh api --paginate "repos/${upstream_repo}/pulls/${pr_number}/commits" --jq '.[].sha'
}

# Cherry-pick only the commits that belong to an upstream PR.
# Never merge the upstream PR branch: that branch is based on upstream main
# and a merge would replay every upstream commit plus is missing, then
# -X theirs would overwrite Capacitor+ files.
#
# Sets CHERRY_PICK_RESOLUTION to clean, theirs, empty, or failed.
cherry_pick_upstream_pr() {
  local upstream_repo="$1"
  local pr_number="$2"
  local _pr_ref="${3:-upstream-pr-${pr_number}}"
  local mode="${4:-auto}"

  CHERRY_PICK_RESOLUTION="failed"

  local shas=()
  local raw_shas=()
  local sha
  mapfile -t raw_shas < <(list_upstream_pr_commit_shas "$upstream_repo" "$pr_number" 2>/dev/null || true)
  for sha in "${raw_shas[@]+"${raw_shas[@]}"}"; do
    [[ "$sha" =~ ^[0-9a-f]{7,40}$ ]] || continue
    # Skip merge commits. cherry-pick without -m cannot apply them.
    if [ "$(command git rev-list --parents -n 1 "$sha" 2>/dev/null | wc -w)" -gt 2 ]; then
      echo "Skipping merge commit ${sha}"
      continue
    fi
    shas+=("$sha")
  done

  if [ "${#shas[@]}" -eq 0 ]; then
    local main_ref=""
    if command git rev-parse --verify refs/remotes/upstream/main >/dev/null 2>&1; then
      main_ref="refs/remotes/upstream/main"
    elif command git rev-parse --verify upstream-main >/dev/null 2>&1; then
      main_ref="upstream-main"
    elif command git rev-parse --verify upstream/main >/dev/null 2>&1; then
      main_ref="upstream/main"
    fi
    if [ -n "$main_ref" ] && command git rev-parse --verify "$_pr_ref" >/dev/null 2>&1; then
      echo "GitHub commit list unavailable; using ${_pr_ref} commits not in ${main_ref}"
      mapfile -t shas < <(command git rev-list --reverse --no-merges "${main_ref}..${_pr_ref}")
    fi
  fi

  if [ "${#shas[@]}" -eq 0 ] || [ -z "${shas[0]:-}" ]; then
    echo "Upstream PR #${pr_number} has no commits"
    CHERRY_PICK_RESOLUTION="empty"
    return 1
  fi

  echo "Cherry-picking ${#shas[@]} commit(s) from upstream PR #${pr_number}"

  if [ "$mode" != "theirs" ]; then
    if cherry_pick_shas "${shas[@]}"; then
      CHERRY_PICK_RESOLUTION="clean"
      echo "Cherry-pick completed cleanly"
      format_after_sync
      return 0
    fi

    echo "Clean cherry-pick hit conflicts."
    abort_in_progress_cherry_pick
    command git reset --hard HEAD >/dev/null 2>&1 || true
    if [ "$mode" = "clean" ]; then
      echo "Leaving the tree clean so a later -X theirs merge can retry."
      CHERRY_PICK_RESOLUTION="failed"
      return 1
    fi
    echo "Retrying and preferring upstream PR hunks on overlapping lines."
  else
    abort_in_progress_cherry_pick
    command git reset --hard HEAD >/dev/null 2>&1 || true
  fi

  if cherry_pick_shas --theirs "${shas[@]}"; then
    CHERRY_PICK_RESOLUTION="theirs"
    echo "Cherry-pick completed by preferring upstream PR hunks on conflicts. Capacitor+ only hunks were kept."
    format_after_sync
    return 0
  fi

  echo "Unable to cherry-pick upstream PR #${pr_number} without leftover conflicts"
  abort_in_progress_cherry_pick
  CHERRY_PICK_RESOLUTION="failed"
  return 1
}

# Return 0 when every commit unique to the upstream PR already has an
# equivalent patch on sync_ref (compared by patch-id, not raw SHA).
upstream_pr_already_applied() {
  local sync_ref="$1"
  local pr_ref="$2"
  local upstream_main_ref="$3"

  if ! git rev-parse --verify "$sync_ref" >/dev/null 2>&1; then
    return 1
  fi
  if ! git rev-parse --verify "$pr_ref" >/dev/null 2>&1; then
    return 1
  fi
  if ! git rev-parse --verify "$upstream_main_ref" >/dev/null 2>&1; then
    return 1
  fi

  local limit
  limit=$(git merge-base "$upstream_main_ref" "$pr_ref") || return 1
  local cherry_out
  cherry_out=$(git cherry "$sync_ref" "$pr_ref" "$limit") || return 1
  if printf '%s\n' "$cherry_out" | grep -q '^+'; then
    return 1
  fi
  return 0
}

# Format only files changed since base_ref so a repo-wide fmt cannot
# add unrelated diffs to a sync PR. Uses real prettier --write (not
# prettier-pretty-check) so Java and TypeScript match plus lint.
format_files_changed_since() {
  local base_ref="$1"

  if ! git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
    echo "Skipping format: base ref ${base_ref} not found"
    return 0
  fi

  local files
  files=$(git diff --name-only "${base_ref}...HEAD" || true)
  if [ -z "$files" ]; then
    echo "No files changed since ${base_ref}, skipping format"
    return 0
  fi

  local prettier_files=()
  local eslint_files=()
  local swift_files=()
  local f
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ -f "$f" ] || continue
    case "$f" in
      *.css|*.html|*.java|*.js|*.mjs|*.ts) prettier_files+=("$f") ;;
    esac
    case "$f" in
      *.ts) eslint_files+=("$f") ;;
    esac
    case "$f" in
      *.swift) swift_files+=("$f") ;;
    esac
  done <<< "$files"

  local prettier_bin=""
  if command -v bun >/dev/null 2>&1; then
    prettier_bin="bunx prettier"
  elif [ -x node_modules/.bin/prettier ]; then
    prettier_bin="node_modules/.bin/prettier"
  fi

  local eslint_bin=""
  if command -v bun >/dev/null 2>&1; then
    eslint_bin="bunx eslint"
  elif [ -x node_modules/.bin/eslint ]; then
    eslint_bin="node_modules/.bin/eslint"
  fi

  if [ "${#prettier_files[@]}" -gt 0 ]; then
    if [ -n "$prettier_bin" ]; then
      echo "Running prettier on ${#prettier_files[@]} changed file(s)"
      # shellcheck disable=SC2086
      $prettier_bin --plugin=prettier-plugin-java --write -- "${prettier_files[@]}" || echo "prettier had some issues, continuing..."
    else
      echo "Skipping prettier: bun and local prettier not found"
    fi
  fi

  if [ "${#eslint_files[@]}" -gt 0 ]; then
    if [ -n "$eslint_bin" ]; then
      echo "Running eslint --fix on ${#eslint_files[@]} changed TypeScript file(s)"
      # shellcheck disable=SC2086
      $eslint_bin --fix -- "${eslint_files[@]}" || echo "eslint had some issues, continuing..."
    else
      echo "Skipping eslint --fix: bun and local eslint not found"
    fi
  fi

  if [ "${#swift_files[@]}" -gt 0 ] && command -v swiftlint >/dev/null 2>&1; then
    echo "Running swiftlint --fix on ${#swift_files[@]} changed Swift file(s)"
    swiftlint --fix --format -- "${swift_files[@]}" || echo "swiftlint had some issues, continuing..."
  fi

  local staged=()
  if [ "${#prettier_files[@]}" -gt 0 ]; then
    staged+=("${prettier_files[@]}")
  fi
  if [ "${#eslint_files[@]}" -gt 0 ]; then
    staged+=("${eslint_files[@]}")
  fi
  if [ "${#swift_files[@]}" -gt 0 ]; then
    staged+=("${swift_files[@]}")
  fi
  if [ "${#staged[@]}" -gt 0 ] && ! git diff --quiet -- "${staged[@]}"; then
    echo "Formatter made changes, committing..."
    git add -- "${staged[@]}"
    git commit -m "style: auto-format code after upstream sync"
  fi
}

# Pick a plus base ref and format files this sync added or changed.
format_after_sync() {
  local base="${SYNC_FORMAT_BASE:-}"
  local head
  head=$(command git rev-parse HEAD)
  if [ -z "$base" ]; then
    # Prefer a plus ref that is still distinct from HEAD. If we merged
    # while on plus itself, the local plus ref has moved with us.
    if command git rev-parse --verify plus >/dev/null 2>&1       && [ "$(command git rev-parse plus)" != "$head" ]; then
      base=plus
    elif command git rev-parse --verify origin/plus >/dev/null 2>&1       && [ "$(command git rev-parse origin/plus)" != "$head" ]; then
      base=origin/plus
    else
      echo "Skipping format after sync: no plus base distinct from HEAD"
      return 0
    fi
  fi
  format_files_changed_since "$base" || {
    echo "format after sync had issues, continuing..."
    return 0
  }
}

# Merge upstream into plus while keeping Capacitor+ customizations.
# Regular merge first; on conflicts retry with -X ours so overlapping
# hunks keep plus and non-overlapping upstream changes still apply.
#
# Sets MERGE_PLUS_PRESERVING_RESOLUTION to clean, ours, or failed
# and MERGE_PLUS_PRESERVING_CONFLICTS to the conflicted file list.
merge_plus_preserving() {
  local commit_message="$1"
  local upstream_ref="${2:-upstream/main}"

  MERGE_PLUS_PRESERVING_RESOLUTION="failed"
  MERGE_PLUS_PRESERVING_CONFLICTS=""

  if git merge "$upstream_ref" --no-edit -m "$commit_message"; then
    MERGE_PLUS_PRESERVING_RESOLUTION="clean"
    format_after_sync
    return 0
  fi

  MERGE_PLUS_PRESERVING_CONFLICTS=$(git diff --name-only --diff-filter=U || true)
  git merge --abort >/dev/null 2>&1 || git reset --hard HEAD >/dev/null 2>&1 || true

  echo "Regular merge conflicted. Retrying with plus-preserving strategy (-X ours)."
  if [ -n "$MERGE_PLUS_PRESERVING_CONFLICTS" ]; then
    echo "Conflicted files (plus version kept for overlapping hunks):"
    echo "$MERGE_PLUS_PRESERVING_CONFLICTS"
  fi

  if git merge "$upstream_ref" -X ours --no-edit -m "${commit_message} (plus-preserving conflicts)"; then
    MERGE_PLUS_PRESERVING_RESOLUTION="ours"
    format_after_sync
    return 0
  fi

  local unmerged
  unmerged=$(git diff --name-only --diff-filter=U || true)
  if [ -z "$unmerged" ]; then
    git merge --abort >/dev/null 2>&1 || true
    return 1
  fi

  local file
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    if git checkout --ours -- "$file" 2>/dev/null; then
      git add "$file"
    elif git rm -f "$file" 2>/dev/null; then
      :
    else
      git merge --abort >/dev/null 2>&1 || true
      return 1
    fi
  done <<< "$unmerged"

  if [ -n "$(git diff --name-only --diff-filter=U)" ]; then
    git merge --abort >/dev/null 2>&1 || true
    return 1
  fi

  if command git rev-parse -q --verify MERGE_HEAD >/dev/null; then
    git commit --no-edit || git commit -m "${commit_message} (plus-preserving conflicts)"
    MERGE_PLUS_PRESERVING_RESOLUTION="ours"
    format_after_sync
    return 0
  fi

  git merge --abort >/dev/null 2>&1 || true
  return 1
}


is_plus_like_branch() {
  local branch="$1"
  case "$branch" in
    plus|sync/plus-upstream-*|sync/upstream-main-*) return 0 ;;
  esac
  return 1
}

# The scheduled workflows still call `git merge` on upstream PR branches
# and `git merge -X theirs` on plus. Those YAML files cannot always be
# updated (pushing workflow files needs the GitHub workflow scope).
# Intercept those calls after this file is sourced so plus is not wiped.
git() {
  if [ "${1:-}" = "merge-base" ] && [ "${2:-}" = "--is-ancestor" ] && [ -n "${3:-}" ] && [ -n "${4:-}" ]; then
    if command git log "$4" --format=%B 2>/dev/null | grep -Fq "cherry picked from commit ${3}"; then
      return 0
    fi
  fi

  if [ "${1:-}" = "merge" ]; then
    local arg
    local pr_ref=""
    local has_abort=false
    local has_theirs=false
    local merging_upstream_main=false
    for arg in "$@"; do
      case "$arg" in
        --abort) has_abort=true ;;
        theirs|-Xtheirs) has_theirs=true ;;
        upstream/main) merging_upstream_main=true ;;
        upstream-pr-*) pr_ref="$arg" ;;
      esac
    done

    if [ -n "$pr_ref" ] && [ "$has_abort" = false ]; then
      local pr_number="${pr_ref#upstream-pr-}"
      echo "Intercepting merge of ${pr_ref}: cherry-picking only commits from upstream PR #${pr_number}"
      if [ "$has_theirs" = true ]; then
        cherry_pick_upstream_pr "${UPSTREAM_REPO:-ionic-team/capacitor}" "$pr_number" "$pr_ref" theirs
      else
        cherry_pick_upstream_pr "${UPSTREAM_REPO:-ionic-team/capacitor}" "$pr_number" "$pr_ref" clean
      fi
      return $?
    fi

    if [ "$has_theirs" = true ] && [ "$merging_upstream_main" = true ] && [ "$has_abort" = false ]; then
      local branch
      branch=$(command git rev-parse --abbrev-ref HEAD)
      if is_plus_like_branch "$branch"; then
        echo "Intercepting upstream-preferred merge on ${branch}: using plus-preserving merge"
        merge_plus_preserving "chore: sync plus with upstream main" upstream/main
        return $?
      fi
    fi
  fi

  command git "$@"
}
