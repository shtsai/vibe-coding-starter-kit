# Decisions

One entry per choice that was hard to reverse, cost money, or had two defensible
answers. Written when the decision is made, never rewritten afterwards — if we change
our mind, that is a new entry that says so.

This exists so a future session does not re-argue a settled question, and so the owner
can remember in six months why the app is shaped the way it is.

---

## YYYY-MM-DD — Example: where the database lives

**Decided:** Neon Postgres.
**Because:** it has a free tier that fits this app, it can make instant copies of
production to rehearse risky changes on, and it can restore to a point in time.
**Rejected:** a SQLite file — cannot work on Vercel, where the filesystem resets.
**Reversibility:** annoying. The data would move fine, but every query would need
checking. Worth doing once, properly.
