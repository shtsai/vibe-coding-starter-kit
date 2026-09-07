---
name: danger-check
description: Use before any action that is hard to undo, touches production, spends money, reaches the outside world, or deletes something. Lists what always needs a human yes and how to ask for it.
---

# Stop and get a yes

The owner cannot catch a dangerous change by reading the code. So the check has to be
here, before the action, and it has to be you who raises it.

## Always stop for these

**Production data**
- any migration, script, or query that writes to the production database
- any bulk `UPDATE` or `DELETE`, and anything without a `WHERE`
- `DROP TABLE`, `DROP COLUMN`, or any migration that loses information
- (reading production to diagnose is fine — prefer it to guessing)

**Git and files**
- pushing to `main` directly, `push --force`, rewriting history, deleting branches
- deleting files or code the current task did not create — including "cleanup" of code
  that looks unused. Things that look dead are often reached by a composed path
  (`/icons/${name}.png`), by a workflow file, by an old URL people still have bookmarked,
  or by a table that exists in production
- committing anything with real personal data in it — an export, a CSV, a screenshot of
  real accounts. Git history is permanent even in a private repo

**Secrets**
- adding, changing, or printing an API key, password, or connection string
- secrets live in `.env.local` (gitignored) and Vercel's env settings, nowhere else, and
  never echoed into the chat

**Money and the outside world**
- signing up for anything paid, or upgrading a plan
- sending real email, push notifications, webhooks, or posting to a third-party API from
  a development machine. Gate those on running in production, and gate on *where the code
  is running*, not on whether a credential happens to exist — a dev machine usually has
  the real one

**Behaviour that affects other people**
- anything in authentication or permissions
- anything that changes what a user other than the owner can see

## How to ask

Three sentences. What you want to do, what could go wrong, what the undo is.

> I want to drop the `legacy_notes` column. It holds 412 rows of text nothing reads any
> more, as far as I can tell. Once dropped it is gone unless we restore last night's
> backup. Shall I?

Do not bury it at the end of a long message, and do not proceed while asking. Wait.

## What a yes covers

A yes covers **that action, now**. It does not carry over to the next similar one, and it
does not turn into standing permission. If the owner says "stop asking me about
migrations", write that down in `CLAUDE.md` as an explicit standing decision — then it is
a rule, not a memory.

If the owner reaffirms after you have raised a concern, that is their call. Say so once,
then do the work properly and completely.

## The safer alternative is usually cheap

Before asking for permission to do the risky thing, check whether there is a version that
needs no permission: a soft delete instead of a delete, a new column instead of a rename,
a dry run that prints what it *would* change, a Neon branch of production to rehearse on.
Offer that instead — it is often the same amount of work and cannot hurt anyone.
