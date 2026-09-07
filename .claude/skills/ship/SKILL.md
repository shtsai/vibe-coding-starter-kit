---
name: ship
description: Use when the user says "ship it", "/ship", "commit this", "land it", or asks to publish finished work. Owns the whole flow — bring docs current, run the local gate, then land through the CI-gated ship script. Never hand-roll git add/commit/push instead.
---

# Ship it

The owner cannot review a diff, so the gate is the review. Follow every step.

## 1. Make sure the work is actually finished

Run, and paste the real output:

```bash
npm run lint && npm run typecheck && npm test
```

If anything is red, fix it. Do not ship around a failing test, even one that was already
failing before you started — say so and fix it, or stop and explain why you cannot.

If the change touched the UI, load the page and look at it before continuing.

## 2. Bring the written record current

- New pattern, new constraint, or a gotcha the next session must know → the relevant
  `CLAUDE.md` (repo root, or the feature's own).
- A decision with alternatives → append to `docs/DECISIONS.md`.
- Do NOT paste implementation detail into the root `CLAUDE.md`. It loads every session;
  keep it an index.

## 3. Commit — one commit

Path-filtered CI diffs the whole PR, so an extra "docs" commit on top re-runs the entire
gate. Stage everything the change needs and make a single commit.

```bash
git add -A && git commit -m "Short imperative title

What changed and why, in two or three lines a non-engineer can follow."
```

Check `git status` first. If something unexpected is staged — an env file, a data export,
a screenshot — stop and ask. See CLAUDE.md §7.8.

## 4. Ship

```bash
npm run ship "Short title of what changed"
```

This runs `.ship/preflight`, pushes a branch, opens a PR, waits for **all** checks, and
squash-merges only if every one is green.

## 5. Report honestly

Tell the owner, in plain language:

- what changed and what they will see differently
- that CI passed (say which checks), or exactly what failed and what you are doing next
- anything you deliberately did not do

**Take the verdict from the artifact, not from the exit code of a command that also did
housekeeping.** If the merge landed but the branch cleanup failed, that is a successful
ship — check the PR's own merged state before calling it a failure.

## If the gate is red

The PR is left open. That is the system working. Fix the cause, commit, and re-run
`npm run ship` — it reuses the same PR. Never reach for a skip flag to get past a red
check without telling the owner what you are skipping and why.
