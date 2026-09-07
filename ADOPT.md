# ADOPT.md — read this first if you are an agent

**Someone gave your owner a link to this repository and asked you to incorporate it into
their app, and to get that app deployed on Vercel with a Neon database.**

Their app currently runs only on `localhost`. Your job is to bring these guardrails into
their codebase and take it live, without breaking what already works and without doing
anything the owner has not agreed to.

**Read this whole file before running a single command.** Then work through the phases in
order. Each phase ends with something you report to the owner in plain language.

**The owner does not read code.** They can run commands, click things, and tell you what
looks wrong. They cannot catch a bad change by reviewing a diff. Every rule in this repo
exists because of that one fact.

---

## Before anything: four rules that hold for the whole job

1. **Never commit a secret.** No `.env`, `.env.local`, API keys, connection strings, or
   passwords in any file you commit. If you need a value from the owner, have them put it
   in `.env.local` themselves — never ask them to paste it into the chat.
2. **Never commit real personal data.** Their local database may contain real names,
   emails, or payments. Do not commit a dump of it. Git history is permanent even in a
   private repo.
3. **Nothing that costs money without an explicit yes.** Everything below fits on free
   tiers. If you hit a paywall, stop and explain the options and prices.
4. **Nothing destructive to their existing app without an explicit yes.** You are adding
   to a working codebase. Their app must still run on `localhost` after every phase.

---

## Phase 0 — Understand what you are adopting, and say so

Do not copy anything yet. First, find out:

- What framework is the app? (`package.json`, or the files at the root.)
- Where does its data live right now — a SQLite file, a local Postgres, JSON files on
  disk, or nothing yet?
- Is it already a git repository? Is it already on GitHub?
- Does it have any tests? Does `npm run build` succeed today?
- Does it read any secrets, and where from?

Then tell the owner what you found, in plain language, and flag anything that will make
this harder. For example: *"Your data is in a file called `data.db` on your laptop. That
file cannot come with us to Vercel — Vercel's servers forget their filesystem every time.
So part of this job is moving that data into Neon. There are about 40 records; I can move
them across."*

**If the app is not Next.js**, stop here and raise it as a decision (see
`.claude/skills/explain-the-decision/SKILL.md`):

- **A Vite/React front end with no backend** — deploys to Vercel fine. Adopt the kit, but
  the `e2e` CI job and the Neon parts only apply once there is a backend. Say so plainly
  rather than wiring up a database nobody uses.
- **An Express/Fastify server, or a Python backend** — Vercel can host it, but the fit is
  worse than Next.js and the kit's CI and auth guidance assume Next. Give the owner the
  real choice: keep the current stack and adapt the kit (less work now, some of the kit's
  safety nets do not apply), or port to Next.js (more work now, everything here fits).
  Recommend one. Do not silently start a rewrite.
- **Anything else** — describe it, recommend, and wait.

**Checkpoint:** the owner knows what you found and has agreed on the shape of the work.

---

## Phase 1 — Copy the kit in

Clone this repo somewhere temporary and copy the files across. Do **not** overwrite files
their app already has.

```bash
git clone <this repo url> /tmp/vibe-starter
cd <their app>
```

Copy in, as-is:

- `CLAUDE.md` — if they already have one, **merge**: keep their app-specific facts, add
  every rule from this one. Do not lose either side.
- `.claude/skills/` — all six
- `.claude/settings.json` — if they have one, merge the `allow` and `deny` lists
- `.github/workflows/ci.yml`
- `.ship/preflight` (keep it executable: `chmod +x`)
- `scripts/ship.sh` (`chmod +x`), `scripts/check-prod-migrations.ts`
- `.env.example`
- `docs/DECISIONS.md`, `docs/ARCHITECTURE.md`
- `HANDBOOK.md` — this is the owner's, not yours. Copy it and tell them to read it.

Do **not** copy: `README.md`, `SETUP.md`, `ADOPT.md`. Those describe the kit itself, not
their app. Their `README.md` stays theirs.

Then:

- **Fill in `docs/ARCHITECTURE.md`** with what their app actually is — the template is a
  skeleton, and a skeleton left unfilled is worse than nothing.
- **Trim `CLAUDE.md` to the truth.** Its stack table describes what this kit assumes. If
  their app differs and the owner decided to keep it that way, edit the table to say what
  they actually use and note the decision in `docs/DECISIONS.md`. A manual that lies is
  a manual the next session will follow off a cliff.
- Make sure `.gitignore` contains `.env*.local`, `.env`, `node_modules`, `.next`.

**Checkpoint:** their app still runs on localhost, unchanged. Nothing is committed yet.

---

## Phase 2 — Make the commands real

The ship script and CI expect certain npm scripts to exist. Add whichever are missing
(see the appendix in this repo's `SETUP.md` for the full block):

`lint`, `typecheck`, `test`, `ship`, and — once there is a database —
`db:generate`, `db:migrate`, `db:seed`, `db:deploy-production`,
`db:check-prod-migrations`.

If the app has no tests at all, set up Vitest and write **one** real unit test of existing
logic, plus **one** Playwright test of the app's single most important journey. Watch
both fail first (break the code on purpose, see red, put it back). Two real tests that
have been seen failing are worth more than twenty generated ones that have never been red.

Do not backfill a large test suite now. Tests arrive with the next feature and the next
bug fix — that is the rule in `CLAUDE.md` §4, and it grows the suite in the shape of the
app's real weaknesses.

**Checkpoint:** `npm run lint`, `npm run typecheck` and `npm test` all pass locally. Paste
the output for the owner.

---

## Phase 3 — GitHub, privately

```bash
git status                      # look at every file before staging anything
```

Check for secrets and real data **before** the first commit — after it, they are in the
history for good.

```bash
git add -A && git commit -m "Add guardrails: CI, ship gate, tests, docs"
gh repo create <app-name> --private --source=. --push
```

If it is already on GitHub, push a branch and use `npm run ship` instead of pushing to
`main` — from here on, `ship` is the only way to `main`.

**Checkpoint:** the code is on GitHub, private, and CI ran on the pull request.

---

## Phase 4 — The database moves to Neon

Skip this phase entirely if the app has no backend data. Do not create a database nobody
uses.

Vercel's servers have no permanent filesystem: a SQLite file or anything written to disk
is wiped on every deploy. That is why the data has to move.

1. Owner creates a Neon project at neon.tech (free, sign in with GitHub).
2. In it, create **two branches** of production: `dev` and `ci`. Explain why: their laptop
   and the automated tests must never point at the real data. A branch is an instant
   copy — a mistake on one costs nothing.
3. Add Drizzle and write `db/schema.ts` to describe the tables the app already uses.
   Generate the first migration with `npm run db:generate` and **read the SQL it produced**
   before applying it.
4. `npm run db:migrate` against the `dev` branch. Point the app at it and confirm it still
   works locally.
5. **Moving their existing data is a separate, explicit step.** Write a one-off import
   script that reads the old store and writes to Neon. Before running it, tell the owner
   how many records it will move and what happens if it goes wrong. Run it against `dev`
   first and check the numbers match. Then ask before touching production.

The owner fills in `.env.local` themselves from `.env.example`: `DATABASE_URL` is the
**dev** branch, `PRODUCTION_DATABASE_URL` is production, `AUTH_SECRET` is
`openssl rand -base64 32`.

**Checkpoint:** the app runs locally against Neon's `dev` branch with their data in it,
and their original local database file is still untouched as a fallback.

---

## Phase 5 — Deploy to Vercel

1. Owner signs in to vercel.com with GitHub and imports the repository.
2. Add environment variables in Vercel → Settings → Environment Variables:
   `DATABASE_URL` (the **production** Neon connection string) and `AUTH_SECRET` (the same
   value as local). The owner pastes these into Vercel themselves.
3. **Run the migrations against production before the first deploy finishes**, and
   explain why: Vercel deploys code but never runs migrations, so code that reads a table
   production does not have will fail for every visitor. This is the single most common
   way a working app breaks on going live, and `.ship/preflight` now blocks it — do not
   disable that check to get a deploy through.
4. Deploy. Then **open the live URL and use the app.** Sign in, create something, reload.
   A green build is not a working app.

**Checkpoint:** the owner has a public URL that works, and knows that every push to `main`
now updates it.

---

## Phase 6 — Close the loop

```bash
gh secret set CI_DATABASE_URL      # the Neon `ci` branch connection string
```

Then prove the whole chain end to end, because a safety net nobody has tested is not a
safety net:

1. Make one trivial visible change — a heading.
2. Write a test for it. Watch it fail first.
3. `npm run ship "Test the deploy loop"`.
4. Show the owner the CI checks going green, the merge, and the change live on the URL.

**If any part of this fails, fix it now.** This loop is the protection for everything they
build from here.

---

## Phase 7 — Backups, then hand over

Neon can restore to a point in time, which is a real safety net — but only if someone
notices in time, and it disappears if the database does. Set up a scheduled dump to
storage the owner controls, plus a **separate** check on its own schedule that alerts them
when a night's backup is missing. A freshness check that runs inside the backup job can
never fail, so it must not live there.

Then write the owner a short handover:

- their live URL, and that pushing to `main` updates it
- where the data now lives, and that their laptop points at a copy, not the real thing
- the one command they need: `npm run ship "what changed"`
- that `HANDBOOK.md` is theirs to read, and the most valuable habit in it is asking
  *"show me the output"* every time you say something works

---

## Things not to do

- Do not rewrite or restructure their app while adopting the kit. Adopt first, ship it
  green, and raise any restructuring separately as a decision.
- Do not delete code that looks unused. It is often reached by a URL, a config file, or a
  path built from a string — and a schema for a table that exists in production is never
  dead code.
- Do not point their laptop at the production database, ever.
- Do not push to `main`. Use `npm run ship`.
- Do not skip a failing check to get something through. If a check fails and you believe
  it is wrong, say so and explain why — do not reach for a skip flag quietly.
- Do not report a phase as complete without pasting what you actually ran and saw.
