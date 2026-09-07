#!/usr/bin/env bash
set -euo pipefail
#
# ship — the only way code reaches production.
#
#   npm run ship "Short title of what changed"
#
# Runs the repo pre-flight, moves your commits to a branch, opens a pull request,
# waits for EVERY check to finish, and squash-merges to main only if all of them
# are green. If anything is red the PR is left open and nothing is merged.
#
# Why not just push to main? Because nobody reads the diff here. The checks are
# the review, and this makes them impossible to skip by accident.

command -v gh >/dev/null || { echo "ship: the GitHub CLI (gh) is not installed. Run: brew install gh" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "ship: not signed in to GitHub. Run: gh auth login" >&2; exit 1; }

cd "$(git rev-parse --show-toplevel)"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "ship: you have uncommitted changes. Commit them first." >&2; exit 1
fi

# --- pre-flight: repo-specific gates CI cannot express. Nothing is pushed yet. ---
if [ -x .ship/preflight ]; then
  if [ "${SHIP_SKIP_PREFLIGHT:-}" = "1" ]; then
    echo "ship: ⚠️  SHIP_SKIP_PREFLIGHT=1 — skipping pre-flight on purpose" >&2
  else
    echo "ship: running pre-flight checks…"
    .ship/preflight || { echo "ship: ✗ pre-flight failed. NOTHING was pushed. Fix the above and try again." >&2; exit 1; }
  fi
fi

git fetch -q origin main
ahead="$(git rev-list --count origin/main..HEAD)"
[ "$ahead" -gt 0 ] || { echo "ship: nothing to ship — no new commits." >&2; exit 1; }

title="${1:-$(git log -1 --pretty=%s)}"
cur="$(git rev-parse --abbrev-ref HEAD)"
if [ "$cur" = "main" ] || [ "$cur" = "HEAD" ]; then
  branch="ship/$(date +%Y%m%d-%H%M%S)"
  git branch "$branch" HEAD
else
  branch="$cur"
fi

echo "ship: shipping $ahead commit(s) on '$branch' → main"
git push -q -u origin "$branch"

if pr_url="$(gh pr view "$branch" --json url -q .url 2>/dev/null)" && [ -n "$pr_url" ]; then
  echo "ship: reusing the open pull request → $pr_url"
else
  pr_url="$(gh pr create --base main --head "$branch" --title "$title" \
              --body "$(git log --pretty='- %s' origin/main..HEAD)")"
  echo "ship: pull request opened → $pr_url"
fi

# --- wait for OUR CI to register, not just for a deploy bot ---
# Vercel reports green within seconds of the push; that only says the app built.
# It says nothing about lint, types or tests. Merging on it is merging unverified.
head_sha="$(git rev-parse HEAD)"
slug="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
echo "ship: waiting for the CI run to appear for ${head_sha:0:8}…"
seen=0
for _ in $(seq 1 72); do
  n="$(gh api "repos/$slug/actions/runs?head_sha=$head_sha&per_page=20" \
        --jq '[.workflow_runs[] | select(.event == "pull_request")] | length' 2>/dev/null || echo 0)"
  [ "${n:-0}" -gt 0 ] && { seen=1; break; }
  sleep 5
done
if [ "$seen" -eq 0 ]; then
  echo "ship: ✗ no CI run registered for this commit — refusing to merge unverified." >&2
  echo "ship:   This is usually a merge conflict with main. Try: git pull --rebase origin main" >&2
  echo "ship:   PR is open at $pr_url" >&2
  exit 1
fi

echo "ship: waiting for all checks…"
if ! gh pr checks "$branch" --watch --fail-fast; then
  echo "" >&2
  echo "ship: ✗ a check failed. NOTHING was merged — the pull request is still open:" >&2
  echo "ship:   $pr_url" >&2
  echo "ship:   Fix the problem, commit, and run ship again (it reuses this same PR)." >&2
  exit 1
fi

echo "ship: all checks green — merging."
gh pr merge "$branch" --squash --delete-branch --subject "$title" \
  --body "Merged by ship. All CI checks green on ${head_sha:0:8}." || true

# Take the verdict from the pull request itself, not from the exit code above —
# branch cleanup can fail after a successful merge and would report a good ship
# as a failure.
merged="$(gh pr view "$branch" --json mergedAt -q .mergedAt 2>/dev/null || echo "")"
if [ -z "$merged" ] || [ "$merged" = "null" ]; then
  echo "ship: ✗ the merge did not land. See $pr_url" >&2; exit 1
fi

git checkout -q main 2>/dev/null || true
git pull -q --ff-only origin main
git branch -q -D "$branch" 2>/dev/null || true

echo "ship: ✅ shipped. main is up to date, and Vercel is deploying it now."
