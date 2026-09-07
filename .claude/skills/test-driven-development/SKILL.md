---
name: test-driven-development
description: Use before writing implementation code for any feature or bug fix. The test comes first, is watched failing, and only then is the code written. Covers the three test layers in this repo and the ways a test can be green while proving nothing.
---

# Test first — and watch it fail

The owner cannot review your code. The test suite is the review. A test that was never
seen red is not a review; it is a comment that costs money to run.

## The loop

1. **Write the test.** Name it after the behaviour, not the function:
   `"a user cannot edit someone else's note"`, not `"testUpdateNote"`.
2. **Run it. Watch it fail — for the reason you expect.** If it fails with
   "cannot find module", it has not tested anything yet. If it *passes*, stop: either the
   feature already exists, or the test cannot fail. Find out which before writing code.
3. **Write the smallest code that makes it pass.**
4. **Run the whole suite.** A new test that breaks two old ones is information, not noise.

For a bug: the test reproduces the bug first. **Every bug fix ships with a test that is
red without the fix.** That is how the suite grows in the shape of this app's real
weaknesses rather than in the shape of what was easy to test.

## Which layer

- **Unit — `lib/foo.test.ts`, next to the code.** Pure functions: totals, dates,
  formatting, "is this user allowed to". No database, no network. Most tests live here,
  and the way to get more of them is to pull logic *out* of routes and components into
  plain functions.
- **Route tests — one per API route.** Four cases, minimum:
  not signed in → 401; signed in as the wrong user → 403; malformed input → 400;
  valid input → the row in the database looks exactly like you expect.
- **Browser — `tests/*.spec.ts` (Playwright).** Only journeys whose breakage would ruin
  the owner's day: sign in, create the main thing, see it in the list, edit it, sign out.
  Browser tests are slow; five good ones beat fifty.

## Ways a test is green and proves nothing

Check your new test against this list before moving on.

- **It was never red.** The single most common failure. Run it before the implementation.
- **It asserts existence, not value.** `expect(res.body).toHaveProperty("total")` passes
  when `total` is `undefined`. Assert the number.
- **The fixture was built by hand.** A fixture you typed cannot fail on the bug in the
  function that normally produces it. Compose fixtures through the real code path.
- **The fixture is too clean.** Real input has empty strings, emoji, a name with an
  apostrophe, a number that is zero. A test whose numbers are all `1` cannot notice a
  multiplication that should have been an addition.
- **It tests the branch directly, not the branch the app takes.** If the decision is a
  ternary buried in a big function, export the decision as its own named function and
  test that — otherwise the test proves the right branch works while the app runs the
  other one.
- **It leaves the database dirty.** Run any new database-touching test *twice*. If the
  second run fails, it is your test, not the product.
- **It compares against the real clock.** `new Date()` in a test is a time bomb: it
  passes today and fails for good on some date nobody chose. Pin the clock.

## Before saying it works

Paste the actual output of `npm test`. Never report a test as passing because it should.
