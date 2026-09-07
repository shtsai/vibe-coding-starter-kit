---
name: explain-the-decision
description: Use when a technical choice is hard to reverse, costs money, affects other people's data, or has two defensible answers — adding a paid service, changing the database shape, picking a library, auth/permissions, a design fork. Produces a plain-language explanation with one clear recommendation, then records it in docs/DECISIONS.md.
---

# Explain the decision, then recommend one

The owner is not an engineer. They are perfectly capable of deciding — once the trade-off
is in words they use. Your job is translation plus a recommendation, not a menu.

## When this fires

- money: a new paid service, a plan upgrade, anything metered
- data: a schema change that loses information, or a new place data is stored
- other people: authentication, permissions, anything a stranger can reach
- lock-in: a dependency or vendor that would be real work to leave
- a genuine fork where the wrong choice means rework later

**It does not fire for routine work.** Variable names, which helper to reuse, how to split
a component — decide those yourself and say what you did in one line. Asking about
everything is its own failure mode.

## The format

Keep it under a screen. No jargon without a translation in the same sentence.

> **The choice:** one sentence saying what we are picking between, and why it came up now.
>
> **Option A — <name>**
> What it is, in one plain sentence.
> Costs: money per month, and roughly how long it takes to build.
> If we change our mind later: easy / annoying / painful, and why.
>
> **Option B — <name>** (same three lines)
>
> **What I'd do: A.** One or two sentences on why — the reason should be about *your*
> situation, not about which is fashionable.
>
> **What I need from you:** a yes, or a question.

## Rules

- **Say the reversibility out loud.** A cheap, easy-to-undo choice barely needs a
  discussion; an expensive, permanent one deserves the whole format. Most beginner regret
  is not "we picked wrong", it is "we picked something we could not leave".
- **Name the recurring bill, not just the setup cost.** "$20/month forever" lands
  differently from "a paid add-on".
- **Give real numbers when you have them** — free tier limits, how many rows, how many
  minutes of build time. If you do not have them, go and look before writing the options.
- **Never present a fake choice** to look thorough. If one option is clearly right, say
  so in two sentences and move on.
- If the owner picks the other option, that is the decision. Record it and build it
  properly — do not re-litigate, and do not build it half-heartedly.

## Then record it

Append to `docs/DECISIONS.md`:

```markdown
## YYYY-MM-DD — <the choice>
**Decided:** <what we picked>
**Because:** <one or two sentences>
**Rejected:** <the other option, and the one thing that ruled it out>
**Reversibility:** <easy / annoying / painful — and what leaving it would involve>
```

This file is why a future session does not re-argue a settled question, and why the owner
can remember in six months why the app is shaped the way it is.
