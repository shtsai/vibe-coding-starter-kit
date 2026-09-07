# How this app is put together

Keep this file current — it is what a new session reads to understand the app without
opening twenty files. Two screens maximum. If it grows past that, the detail belongs in
a feature's own `CLAUDE.md`.

## What it does

<One paragraph. What the app is for, and who uses it.>

## The pieces

- **`app/`** — the pages people see, and the API routes the pages call. Kept thin: a
  route authenticates, validates its input, calls a function in `lib/`, and returns.
- **`lib/`** — the actual logic, as plain functions. This is where the tests live, and
  the reason to keep routes thin.
- **`db/schema.ts`** — every table, in one file. The single source of truth.
- **`db/migrations/`** — generated files that bring a database up to match the schema.
  Committed to git, never hand-edited.
- **`components/`** — the UI pieces.
- **`tests/`** — browser tests for the handful of journeys that really matter.

## The data

<List the main tables and, in one line each, what a row means.>

## Rules that are easy to break by accident

- Who a user is comes from the server session. A request never says who it is.
- Deleting sets `status = 'deleted'`. Nothing removes rows for good except a deliberate
  cleanup job.
- Money is stored as whole cents. Dates are stored in UTC.
- Production migrations are run by hand, BEFORE the code that needs them is pushed.
