---
name: database-changes
description: Use whenever the database shape or its data changes — adding a table or column, renaming, backfilling, deleting rows, or running anything against production. Covers the migration flow, the deploy ordering trap, and what needs a human yes.
---

# Changing the database

The database is the one part of this app where a mistake is not undoable by editing code.
Treat every change here as one notch more serious than it feels.

## The normal flow (adding a table or column)

```bash
# 1. Edit db/schema.ts — this is the single source of truth
# 2. Generate the migration file (never hand-write one)
npm run db:generate
# 3. Read the generated SQL. Actually read it.
# 4. Apply it to your local/dev database
npm run db:migrate
# 5. Write and run the tests, then commit BOTH schema.ts and the migration file
```

The generated file in `db/migrations/` is committed and never edited afterwards. If it is
wrong, generate a new migration that corrects it.

## The ordering trap — this is the one that takes the site down

**Vercel deploys code on push. It does not run migrations.** So code that reads a new
column will 500 for every visitor in the window between the deploy and the migration.

The order is always:

1. apply the migration to production
2. *then* push the code that needs it

```bash
npm run db:deploy-production   # applies pending migrations to prod — needs a human yes
```

`.ship/preflight` refuses to ship when production is behind the migration files, which is
what makes this safe to forget. Do not disable it to get a ship through.

## Additive first, destructive later (or never)

A column you stop using costs nothing. A column you drop costs the data in it.

- Renaming? Add the new column, backfill it, ship code that writes both and reads the new
  one, and leave the old one alone. Drop it weeks later, deliberately, if ever.
- Deleting records? Set `status = 'deleted'` and filter it out. Only a dated,
  explicitly-approved cleanup job ever runs `DELETE`.
- **Filter with an allow-list, not a deny-list.** `status IN ('active','done')` stays
  correct when a sixth status is added later; `status <> 'deleted'` silently starts
  returning the new one.

## Anything touching production needs an explicit yes

Reading production to diagnose a problem is fine and much better than guessing. Writing to
it — a migration, a backfill script, a one-off `UPDATE`, a data fix — needs the owner to
say yes to that specific action, in this conversation.

Before you ask, know the answers to:

- **How many rows does this touch?** Run the `SELECT` count first, every time.
- **What is the undo?** If the answer is "restore from backup", say that.
- **Have I rehearsed it?** For anything non-trivial, create a Neon branch of production
  (a copy-on-write clone, cheap and instant), run the migration there, point a dev server
  at it, and check the app still works. Then delete the branch.

Then ask like this:

> I want to run a backfill that sets `currency = 'USD'` on 1,204 existing rows that have
> no currency. Rows that already have one are untouched (I checked: 88 of them). If it
> goes wrong the undo is restoring from last night's backup, which loses today's data.
> Shall I run it?

## Backups

Neon's point-in-time restore is a *recovery* mechanism with no *detection* — it only helps
if somebody notices in time, and it dies with the database. Keep a scheduled dump to
storage you control, and check the backups from the consumer side on a separate schedule:
a freshness check that runs inside the backup job can never fail.
