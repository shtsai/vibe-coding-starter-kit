/**
 * Fails when production has migrations it has not applied yet.
 *
 * Called by .ship/preflight before anything is pushed. Fails CLOSED: if it
 * cannot reach production, that is a failure, not a pass — "I could not check"
 * must never look like "all clear".
 *
 * Needs PRODUCTION_DATABASE_URL in .env.local.
 */
import { readFileSync } from "node:fs";
import { neon } from "@neondatabase/serverless";

const url = process.env.PRODUCTION_DATABASE_URL;
if (!url || url.length < 30) {
  console.error(
    "check-prod-migrations: PRODUCTION_DATABASE_URL is missing or empty in .env.local.\n" +
      "  Refusing to pass — an unchecked production is not a checked one."
  );
  process.exit(1);
}

const journal = JSON.parse(
  readFileSync("db/migrations/meta/_journal.json", "utf8")
) as { entries: { tag: string }[] };

const sql = neon(url);

const rows = (await sql`
  SELECT count(*)::int AS n
  FROM information_schema.tables
  WHERE table_schema = 'drizzle' AND table_name = '__drizzle_migrations'
`) as { n: number }[];

const applied =
  rows[0].n === 0
    ? 0
    : ((await sql`SELECT count(*)::int AS n FROM drizzle.__drizzle_migrations`) as {
        n: number;
      }[])[0].n;

const expected = journal.entries.length;

if (applied < expected) {
  const pending = journal.entries.slice(applied).map((e) => `  - ${e.tag}`);
  console.error(
    `\ncheck-prod-migrations: production is BEHIND by ${expected - applied} migration(s):\n` +
      pending.join("\n") +
      `\n\n  Apply them first:  npm run db:deploy-production\n` +
      `  Then ship again. (Vercel deploys code but never runs migrations.)\n`
  );
  process.exit(1);
}

console.log(`check-prod-migrations: ok — production has all ${expected} migration(s).`);
