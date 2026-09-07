# How to work with Claude on this app

The setup only has to happen once. This is the part you'll use every day.

---

## The daily loop

1. **Start a fresh session for each new task.** Type `/clear` between unrelated things.
   A long conversation carrying three abandoned approaches makes Claude slower, more
   expensive, and noticeably worse at the fourth.
2. **Say what you want in terms of what you'd see, not how to build it.**
   Good: *"On the list page I want to filter by month, and remember which month I picked
   when I come back."*
   Less good: *"Add a useState for month and a query param."* You'll get a better answer
   by describing the outcome — that's the whole point of working this way.
3. **Let it write the test first.** If Claude starts editing code without a test, say
   *"test first, please."*
4. **Look at it yourself.** Ask for a screenshot, or run `npm run dev` and click around.
   You are much better at spotting "that button is in the wrong place" than any test.
5. **Say "ship it."** That runs the whole gate. If it comes back red, that's the system
   doing its job — say *"fix it and ship again."*

---

## Sentences worth memorising

| When | Say |
|---|---|
| It's about to do something big | "Before you build that, explain the options and what you'd recommend." |
| You don't understand an answer | "Explain that to me like I don't code." (Not a dumb question — a required one.) |
| It says something is done | "Show me the output." |
| It's been going in circles | "Stop. Tell me what you've learned and what you'd try next." Then `/clear` and restart with that summary. |
| You want to be sure it's safe | "What's the undo if this goes wrong?" |
| Something feels off in the UI | "That doesn't look right — here's a screenshot." Then say what's wrong in ordinary words. |
| It asks permission for something scary | "What exactly will change, and how many rows?" |
| It changed more than you asked | "That's more than I asked for. Undo the extra parts." |

---

## What "done" should look like

A finished piece of work comes back with:

- what changed, in a sentence you understand
- the test output, pasted, actually green
- a screenshot if anything visual changed
- anything it *didn't* do, said out loud

If you get "All set! ✅" and nothing else, ask for the evidence. Every time. It takes ten
seconds and it's the single highest-value habit in this document.

---

## When Claude asks for permission

It's meant to — the rules in `CLAUDE.md` require it for anything hard to undo. When it
does, you'll get: what it wants to do, what could go wrong, and what the undo is.

**Say no, or ask a question, whenever you're unsure.** "What happens if we don't do
this?" and "is there a version of this that can't lose data?" are both excellent
questions, and there usually is one.

The one to be most careful with: anything touching the **production database**. That's
the real data — the app can be redeployed in a minute, the data cannot be re-typed.

---

## Money

Everything here starts free. The things that quietly start costing:

- **Neon** — free up to a storage limit. Ask for the current usage before adding anything
  that stores a lot (files, images, logs).
- **Vercel** — free for personal projects. A commercial one needs a paid plan.
- **GitHub Actions** — free minutes each month. Every push runs the checks, so a hundred
  ships a day would eventually add up.
- **Claude usage** — the biggest one, and the reason for `/clear` between tasks.

Ask *"what does this cost per month?"* before agreeing to anything new. Claude is
required to tell you, and to name the recurring bill rather than just the setup.

---

## Things that will go wrong, and what they mean

**"The site is broken after shipping."** Almost always a database migration that didn't
run. Say: *"Check whether production has unapplied migrations."*

**"My change didn't appear."** Vercel takes a minute; also try a hard refresh. If it's
still missing, say *"prove the deploy contains my change"* — not *"deploy again."*

**"A test is failing and I didn't touch that."** Say so. Don't let it be skipped or
deleted to get a ship through — a test that fails for no reason is information, and
deleting it is how a real bug ships next week.

**"It keeps not working."** Two failed fixes is the limit. `/clear`, then start fresh
with: *"Here's the problem, here's what we already tried and it didn't work."*

---

## The rules that exist for a reason

You'll be tempted to skip these. Each one is here because skipping it has taken a real
app down.

1. **Never push straight to main.** Always `ship`.
2. **Never point your laptop at the production database.** Use a Neon branch.
3. **Never commit real data** — a spreadsheet of real customers, a screenshot with real
   account numbers. Git history is permanent, even in a private repo.
4. **Never paste a secret into a chat.** Keys go in `.env.local` and in Vercel's
   settings. If one leaks, it has to be replaced, not deleted.
5. **Migrate production before pushing the code that needs it.** The pre-flight check
   enforces this — don't disable it.

---

## When to start worrying about structure

For the first few features, one folder is fine. Ask for a re-organisation when:

- a file is over ~400 lines and does several unrelated things
- you have a genuinely separate area of the app (not a second page — a second *product*)
- you find yourself saying "don't touch the X part" — that's the signal X wants its own
  folder and its own `CLAUDE.md`

Say: *"This is getting big. Propose a structure, tell me what it costs to do now versus
later, and recommend one."*
