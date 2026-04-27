#!/usr/bin/env bash
# Sync local + remote staging branch to match origin/main after a squash merge.
#
# After a staging -> main PR is squash-merged, main has a single new commit
# while staging still carries the original feature commits. This script:
#   1. Temporarily lifts force-push protection on staging via the GitHub API
#   2. Fetches origin and hard-resets local staging to origin/main
#   3. Force-pushes (with --force-with-lease) to update remote staging
#   4. Restores the force-push block (always, even on failure)
#
# Usage:
#   bash tools/sync_staging.sh
#
# Run from anywhere inside a git repo with 'origin' pointing at GitHub.
# Requires: gh CLI authenticated with `repo` scope.

set -euo pipefail

# ----- locate repo + parse origin -----
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

REMOTE_URL=$(git remote get-url origin)
OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's#^(git@github\.com:|https?://github\.com/)##; s#\.git$##')
if [[ -z "$OWNER_REPO" || "$OWNER_REPO" == "$REMOTE_URL" ]]; then
  echo "error: could not parse GitHub owner/repo from origin: $REMOTE_URL" >&2
  exit 1
fi

echo "Repo:         $OWNER_REPO"
echo "Working tree: $REPO_ROOT"

# ----- safety: refuse on a dirty working tree -----
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "error: uncommitted changes in working tree. Commit or stash first." >&2
  exit 1
fi

# Remember the original branch so we can return to it on success
ORIGINAL_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")

# ----- protection toggle helpers -----
PROTECTION_OFF='{"required_status_checks":null,"enforce_admins":false,"required_pull_request_reviews":null,"restrictions":null,"allow_force_pushes":true,"allow_deletions":false}'
PROTECTION_ON='{"required_status_checks":null,"enforce_admins":false,"required_pull_request_reviews":null,"restrictions":null,"allow_force_pushes":false,"allow_deletions":false}'

restore_protection() {
  echo
  echo "Restoring force-push block on staging..."
  printf '%s' "$PROTECTION_ON" \
    | gh api -X PUT "repos/$OWNER_REPO/branches/staging/protection" --input - >/dev/null
}

# Always restore protection on exit (success or any error)
trap restore_protection EXIT

# ----- do the sync -----
echo "Lifting force-push block on staging..."
printf '%s' "$PROTECTION_OFF" \
  | gh api -X PUT "repos/$OWNER_REPO/branches/staging/protection" --input - >/dev/null

echo "Fetching origin..."
git fetch origin

echo "Resetting local staging to origin/main..."
git checkout staging
git reset --hard origin/main

echo "Force-pushing staging..."
git push origin staging --force-with-lease

# Return to the branch the user was on (if not staging)
if [[ -n "$ORIGINAL_BRANCH" && "$ORIGINAL_BRANCH" != "staging" ]]; then
  echo "Returning to $ORIGINAL_BRANCH..."
  git checkout "$ORIGINAL_BRANCH"
fi

echo
echo "staging synced to origin/main"
