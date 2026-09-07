# Setup — a brand-new app, from nothing

**Already have an app running on localhost?** This is the wrong file — your agent should
follow [`ADOPT.md`](ADOPT.md) instead, which brings this kit into an existing codebase
and deploys it.

Roughly 45 minutes. Do the steps in order; each one depends on the last.

Anywhere below that says "ask Claude", you can literally paste the quoted line.

---

## 1. Accounts (all free to start)

- **GitHub** — where the code lives. github.com
- **Vercel** — where the app runs. vercel.com — sign in with GitHub
- **Neon** — the database. neon.tech — sign in with GitHub
- **Claude Code** — claude.ai/code

## 2. Tools on your machine

Open Terminal and paste:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install node gh
gh auth login          # choose GitHub.com → HTTPS → login with a browser
```

## 3. Create the app

```bash
cd ~/Desktop
npx create-next-app@latest my-app --typescript --tailwind --app --eslint
cd my-app
git init && git add -A && git commit -m "New app"
gh repo create my-app --private --source=. --push
```

## 4. Drop this kit in

Copy everything from the starter kit into the new folder:

```bash
cp -R ~/Desktop/vibe-starter/. ~/Desktop/my-app/
rm ~/Desktop/my-app/README.md.orig 2>/dev/null || true
```

Then open Claude Code in that folder and say:

> "Read CLAUDE.md, then set up the stack it describes: Drizzle + Neon, Auth.js with a
> simple email/password login, Zod, Vitest and Playwright. Add the npm scripts the ship
> script and CI expect: `typecheck`, `test`, `ship`, `db:generate`, `db:migrate`,
> `db:seed`, `db:deploy-production`, `db:check-prod-migrations`. Write one unit test and
> one browser test that both pass, and show me them passing."

## 5. Databases — two of them, always

In the Neon dashboard, create a project. You now have a production database. Then create
**two branches** of it: `dev` (yours) and `ci` (for the automated tests).

Never point your local machine at production. The whole point of a branch is that a
mistake costs nothing.

Copy `.env.example` to `.env.local` and fill in:

- `DATABASE_URL` → the **dev** branch connection string
- `PRODUCTION_DATABASE_URL` → the **production** connection string
- `AUTH_SECRET` → run `openssl rand -base64 32` and paste the result

`.env.local` is gitignored. It must never be committed, and you should never paste its
contents into a chat.

## 6. Tell GitHub and Vercel about the secrets

```bash
gh secret set CI_DATABASE_URL      # paste the CI branch connection string
```

In Vercel: import the GitHub repo, then under Settings → Environment Variables add
`DATABASE_URL` (production connection string) and `AUTH_SECRET` (the same one).

## 7. Prove the whole loop works before you build anything real

Ask Claude:

> "Make one trivial visible change — a heading on the home page — write a test for it,
> and ship it. Show me the CI checks going green and the live URL afterwards."

If that works end to end, everything above is correct. If it doesn't, fix it now: this
loop is the safety net for everything you build later.

## 8. Turn on backups

Ask Claude:

> "Set up a nightly database backup to storage I control, plus a separate check on its
> own schedule that alerts me when a night's backup is missing. Explain the options and
> costs first."

Neon's built-in restore is a real safety net but only if someone notices in time, and it
disappears with the database. A copy somewhere else is the thing that saves you.

---

## Appendix — the npm scripts this kit expects

Claude should add these to `package.json` in step 4. Check they're there:

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint --max-warnings=0",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "test:e2e": "playwright test",
    "ship": "bash scripts/ship.sh",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate",
    "db:seed": "tsx --env-file-if-exists=.env.local db/seed.ts",
    "db:deploy-production": "DATABASE_URL=$PRODUCTION_DATABASE_URL drizzle-kit migrate",
    "db:check-prod-migrations": "tsx --env-file-if-exists=.env.local scripts/check-prod-migrations.ts"
  }
}
```

`npm run ship` is the one you'll type most. `db:deploy-production` is the one to be
careful with — it changes the real database, and Claude must ask you before running it.
