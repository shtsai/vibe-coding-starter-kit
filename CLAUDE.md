# CLAUDE.md — how we work in this repo

Read this file at the start of every session. It is short on purpose. Everything
conditional lives in `.claude/skills/` and loads on demand.

**Who the owner is:** the person you are working with does not read code. They can run
commands you give them, click things in a browser, and tell you what looks wrong. They
cannot review a diff. That single fact drives every rule below: the safety net has to be
in the repo, not in the review.

---

## 1. The prime directive

**Nothing reaches production that a machine has not proved works.** Tests, CI, and the
ship gate are the review. If a check does not exist for what you changed, write the check
as part of the change.

**When you are not sure, stop and ask — in plain language.** A wrong guess costs the owner
more than a question does. See §6.

---

## 2. Stack (do not change these without a decision doc — §6)

| Layer | Choice | Why |
|---|---|---|
| Framework | Next.js (App Router) + TypeScript strict | One thing to learn, one deploy |
| Hosting | Vercel | Push a branch, get a preview URL |
| Database | Neon Postgres | Serverless, branchable, has point-in-time restore |
| DB access | Drizzle ORM + drizzle-kit migrations | Schema is code, migrations are files in git |
| Auth | Auth.js (JWT sessions) | Standard, no session table to run |
| Validation | Zod at every boundary | Untrusted input never reaches the database |
| Unit tests | Vitest | Fast, runs on every save |
| Browser tests | Playwright | Proves the real user journey |
| Styling | Tailwind | No CSS files to keep in sync |

---

## 3. Architecture rules

**Start flat. Add structure when a second feature exists, not before.**

```
app/           # routes and API handlers only — thin
  api/         #   every handler: authenticate → validate → call lib → return
lib/           # the real logic, plain functions, easy to unit-test
db/
  schema.ts    # the single source of truth for tables
  migrations/  # generated files, committed, never hand-edited
components/    # UI
tests/         # Playwright browser tests
docs/
  DECISIONS.md # why we chose things (§6)
```

When the app grows a genuinely separate area (a second product, not a second page),
give it `src/<area>/` with its own components/lib/schema and its own `CLAUDE.md`, and
re-export its tables from the shared `db/schema.ts`. Do not let two areas import each
other's internals — share only `@/db`, `@/lib/auth`, `@/lib/api`.

**Non-negotiable code rules:**

- **Who you are comes from the server session, never from the request body.** If a route
  reads `body.userId` to decide whose data to touch, that is a security hole. Delete the
  field; do not validate it.
- **Every API route validates its input with Zod before touching the database.**
- **A PATCH/update schema must not invent fields nobody sent.** Zod's `.partial()` keeps
  `.default()` values, so `set({...parsed.data})` silently overwrites fields the user
  never edited. Build update schemas by stripping defaults, not by making create schemas
  optional.
- **Delete means "mark deleted" (`status = 'deleted'`), not `DELETE FROM`.** Only a
  deliberate, dated cleanup job ever removes rows for good.
- **Money and dates:** store money as integer cents, never floats. Store dates as UTC and
  format at render time — a serverless function is not in the owner's timezone.
- **Every outbound call gets a timeout.** No `fetch` without an `AbortSignal.timeout(...)`.
- Leave code cleaner than you found it: dead code, unused imports, and stale comments go
  in files you are already editing.

---

## 4. Testing — write the test first

Load `.claude/skills/test-driven-development/SKILL.md` before implementing anything.

The short version:

1. Write the test. **Run it. Watch it fail for the right reason.** A test you never saw
   red is not a test — it is a comment that costs money to run.
2. Write the smallest code that makes it pass.
3. Run the whole suite before you say you are done.

**Three layers, and what each is for:**

- **Unit (Vitest, `*.test.ts` next to the code)** — pure logic: totals, date maths,
  formatting, permission decisions. Most tests live here. No database.
- **Route tests** — one per API route: unauthenticated gets 401, another user's row gets
  403, bad input gets 400, good input writes exactly what you expected.
- **Browser (Playwright, `tests/`)** — only the handful of journeys that would ruin the
  owner's day if broken: sign in, create the main thing, see it in the list, edit it.

**Rules that stop fake green:**

- **Every bug fix ships with a test that fails without the fix.** No exceptions. This is
  how the suite grows in the shape of the app's real weaknesses.
- Do not assert that a thing merely *exists*; assert the value it holds.
- Do not build a test fixture by hand when a real function could produce it — a
  hand-built fixture cannot fail on the producer's bug.
- If a test needs a comment explaining why it passes, it is testing the wrong thing.

Coverage percentage is not a goal. "Every route has a permission test and every fixed bug
has a regression test" is the goal.

---

## 5. Shipping — the only way to production

**Never `git push` to `main`. Never edit anything in the Vercel or Neon dashboard that
the repo could describe instead.**

To land work, invoke the `ship` skill (`.claude/skills/ship/SKILL.md`) or run:

```bash
npm run ship "Short title of what changed"
```

It: runs pre-flight → moves the commits to a branch → opens a PR → **waits for every CI
check** → squash-merges only if all green → syncs `main`. If anything is red, the PR is
left open and nothing merged.

Two things that make it work and are easy to break:

- **One commit per ship.** A "fix the docs" commit on top re-runs the whole gate.
- **Pre-flight (`.ship/preflight`) runs before anything is pushed**, so a failure costs
  nothing. It is where repo-specific gates live that CI cannot express — today: "does
  production still need a database migration?"

---

## 6. Big decisions — explain, then recommend

Load `.claude/skills/explain-the-decision/SKILL.md` whenever you hit one of these:

- adding a paid service, or anything with a bill
- changing the database shape in a way that is hard to undo
- adding a dependency that would be painful to remove
- authentication, permissions, or anything touching other people's data
- a choice between two designs where switching later means real rework

Do not silently pick. Write the options in the owner's vocabulary (no jargon without a
one-line translation), say what each costs and how reversible it is, **give one clear
recommendation and why**, and record the outcome in `docs/DECISIONS.md`.

Routine choices — a variable name, which component to reuse, how to structure a helper —
are yours. Make them and move on. Asking about everything is its own failure.

---

## 7. Dangerous actions — stop and get a yes

Load `.claude/skills/danger-check/SKILL.md` for the full list and the wording to use.

**Never do these without an explicit, specific "yes" from the owner in this conversation:**

1. Anything against the **production database** — migrations, data edits, scripts, one-off
   queries. (Reading production to diagnose is fine and should be preferred over guessing.)
2. `DROP TABLE`, `DROP COLUMN`, or any migration that loses data.
3. `DELETE` / `UPDATE` without a `WHERE`, or a bulk change to more rows than expected.
4. `git push --force`, rewriting history, deleting branches, or pushing to `main`.
5. Deleting files or code the current task did not create — including "cleanup" of things
   that look unused. Things that look dead are often reached by a composed path, a
   workflow file, or a URL, and the schema for a table that exists in production is never
   dead code.
6. Adding, rotating, or printing a secret. Secrets live in `.env.local` (gitignored) and
   in Vercel's env settings — never in a file you commit, never echoed into the chat.
7. Anything that reaches the outside world from a dev machine: sending email, push
   notifications, webhooks, posting to a third party. Gate those on running in production.
8. Committing any file containing real personal data — an export, a screenshot, a CSV.
   Use synthetic fixtures. Git history is permanent even in a private repo.

When you stop, say **what you want to do, what could go wrong, and what the undo is.**
"I'd like to drop the `old_notes` column. It has 412 rows. Once dropped the data is gone
unless we restore from last night's backup. Should I?"

---

## 8. Token efficiency (how you work, never what you build)

Cheap context is about *your* habits. It never justifies a worse design or a shortcut in
the product.

- Explore with Grep/Glob and read only the files the task needs. Never `ls -R` or `find /`.
- Keep this file small. Anything situational belongs in a skill.
- One task per session. Tell the owner to `/clear` between unrelated tasks — a fresh
  session with a better prompt beats a long one carrying failed approaches.
- After two failed attempts at the same problem, stop, say what you learned, and ask for
  a fresh session rather than trying a third variation.
- Do not fan out subagents for implementation. A read-only search agent that saves you
  reading twenty files is fine; one agent per task is not.

---

## 9. Before you say "done"

- [ ] `npm run lint` and `npm run typecheck` pass
- [ ] `npm test` passes, and the new test fails without the change
- [ ] If UI changed: you loaded the page and looked at it — alignment, overflow, empty
      state, what happens while it is loading, what happens when it errors
- [ ] If the database changed: a migration file is committed and §7 was honoured
- [ ] The owner has a one-paragraph summary in plain language

Never report something as working because it should work. Run it and paste what you saw.
