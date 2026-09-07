---
name: verify-it-works
description: Use before claiming any change is done, and whenever proving a UI change works — driving the page, checking layout, loading and error states. Evidence before claims.
---

# Prove it, then say it

"It should work" is not a report. Run the thing and paste what you saw.

## For any change

```bash
npm run lint && npm run typecheck && npm test
```

Paste the real output — not a summary of it, and never output from a previous run.

A green lint and typecheck say the code compiles. They say nothing about whether the page
renders: a value passed across the server/client boundary that cannot be serialised, a
missing environment variable, an undefined import — all of these compile fine and blank
the page. So:

## For any UI change: load the page and look at it

Start the app (`npm run dev`), open the page, and check, in this order:

1. **Does it render at all?** Check the browser console for errors — a blank section with
   a red console line is the commonest failure that every other check misses.
2. **Loading.** What is on screen during the second before data arrives? A spinner, a
   skeleton, or a jarring empty box that will make the owner think it is broken?
3. **Empty.** What does it look like with no data? An empty state must say what is empty
   and offer a way forward, not just be blank.
4. **Error.** Turn the network off, or break the request on purpose. Does it say something
   a person can act on, or does it spin forever?
5. **Long content.** Paste a 200-character title in. Does it wrap, ellipsise, or push the
   layout sideways?
6. **Narrow.** Resize to phone width. Most of this app will be used on a phone.
7. **Look at it.** Alignment, spacing, contrast, anything visibly off. If something looks
   wrong and is not yours, fix it anyway or say so — do not walk past a visible defect.

Take a screenshot and show the owner. They cannot read the diff, but they can absolutely
tell you the button is in the wrong place.

## When automating a browser check (Playwright)

- After every click, assert something **changed**. A click on a disabled button reports
  success and does nothing; the failure then surfaces at the next step and blames the
  wrong control.
- Address elements by a stable `data-testid`, never by their visible text or position —
  a selector keyed on appearance turns every restyle into a pile of fake failures.
- Wait for the state the action causes, never for a fixed number of seconds.
- Run any new test twice. If run two fails, your test left state behind.

## The honest report

Say what you ran, what passed, what you did not check, and anything you left undone.
If a test fails, show the failure. A confident wrong "all set" costs the owner far more
than an honest "tests pass, but I could not check the email sending locally".
