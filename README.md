# Vibe-coding starter kit

> ## 🤖 Agents start here
>
> **If someone gave you a link to this repo and asked you to add it to their app: read
> [`ADOPT.md`](ADOPT.md) in full before running anything.** It is the step-by-step for
> bringing these guardrails into an existing codebase and taking it live on Vercel + Neon.
>
> Starting a brand-new app instead? Use [`SETUP.md`](SETUP.md).
>
> Either way, [`CLAUDE.md`](CLAUDE.md) is the operating manual you follow from then on.

A set of guardrails to drop into a new repo so that someone who doesn't read code can
build real software with Claude — and not break things.

It is deliberately *not* a code template. It is the part that is hard to reconstruct: the
rules, the safety gates, and the workflow. The app itself you generate in five minutes.

## What's in here

| File | Who reads it | What it does |
|---|---|---|
| `CLAUDE.md` | Claude, every session | The operating manual: stack, architecture rules, testing, shipping, what needs your permission |
| `.claude/skills/*` | Claude, on demand | Six playbooks that load only when relevant, so the always-on manual stays small |
| `.claude/settings.json` | Claude Code | Pre-approves safe commands (fewer interruptions) and blocks dangerous ones outright |
| `.github/workflows/ci.yml` | GitHub | Runs lint, types, unit tests and browser tests on every change |
| `scripts/ship.sh` | you (`npm run ship`) | The only path to production. Won't merge unless every check is green |
| `.ship/preflight` | the ship script | Refuses to ship while the production database is behind |
| `scripts/check-prod-migrations.ts` | the pre-flight | The check itself |
| `.env.example` | you | The secrets the app needs, and where they go |
| `docs/DECISIONS.md` | you and Claude | Why things are the way they are |
| `docs/ARCHITECTURE.md` | Claude | A two-screen map of the app |
| `ADOPT.md` | **an agent, once** | How to add this kit to an app that already exists and deploy it to Vercel + Neon |
| `SETUP.md` | you, once | Day-one setup for a brand-new app |
| `HANDBOOK.md` | you, often | How to actually work with Claude day to day |

## How to use it

**You already have an app running on localhost:** hand your agent this repo's link and say
*"read ADOPT.md and follow it."* It covers copying the kit in, getting the code onto
GitHub privately, moving your data to Neon, deploying to Vercel, and proving the whole
loop works end to end.

**Starting from nothing:**

1. Read `SETUP.md` and do it once.
2. Read `HANDBOOK.md` — it's the one that changes how well this goes.
3. Build things. Say "ship it" when you're happy.

## The three ideas behind all of it

**The tests are the review.** Nobody is going to read the code, so a machine has to
prove it works before it goes live. That's why the test rules are strict and why
`ship` refuses to merge on red.

**Undo is worth more than speed.** Soft deletes, additive migrations, backups checked
from the outside, one commit per ship. Almost everything here is buying the ability to
change your mind.

**A permission you have to remember is not a permission.** The rules about what needs
your yes are written in the repo, and the genuinely dangerous commands are blocked in
settings — not left to Claude's judgment on a busy afternoon.
