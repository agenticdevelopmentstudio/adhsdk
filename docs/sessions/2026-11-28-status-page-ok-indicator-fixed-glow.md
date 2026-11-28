# Session: a Mac freeze traced to a status page that repainted every frame

- **Date:** 2026-11-28
- **Session:** `2bdaf475-d6e4-4516-809b-13e1727a4edd`
- **Branch:** `still-ok-indicator` (merged as `757cd61f1`..`0e9974271`, PR #57)

## Orientation

The session started in the monitr repo with a Mac that had stopped responding
for many seconds. The cause was swap exhaustion: one stuck
`PerfPowerServicesSignpostReader` process held 144 GB. Looking for what feeds
that process led to the Watchdog app, whose window shows the lewis status site
and was committing a frame 60 times a second while the page looked still. The
page was not still: the Overview's big green indicator animated its glow on an
endless 3.6 second loop. This session changed that glow to a fixed one in
`status-web`, and merged it. Nothing was deployed, so the live site still
animates until a site is deployed with this toolkit commit.

## Decisions

- **The OK indicator's glow is fixed, not animated.** `.adh-indicator-ok` in
  `packages/web/packages/status-web/src/styles/panels.css` now has a fixed
  `filter: drop-shadow(0 0 20px … 42%)`, the middle of the old pulse's range,
  the same way `.adh-indicator-warn` already worked. Why: an animated `filter`
  cannot run on the compositor, so the browser repaints the indicator on every
  frame for as long as the animation runs, and "ok" is the state a status page
  is left open in for days.
- **The fix went into the site, not only into Watchdog.** The user asked for
  the site itself to stop animating when idle. A host app can guard against a
  busy page, but every other host and browser tab showing the page pays the
  same cost.
- **The red "down" indicator keeps its pulse.** It is an alarm, and the request
  was about the idle state. This leaves a known cost; see Open threads.
- **A test pins the rule.** `src/styles/panels.test.ts` fails if the ok or warn
  glow gains an animation. It was written from a code-review finding.
- **The tests were not run.** The user stopped a full-suite run and said to
  continue without tests. The new test and the rest of the suite have not been
  run against this change.

## Considered and rejected

- **Running the whole toolkit suite for this change.** The development
  playbook's scope script returned "run all" because `panels.css` sits in a
  tier that `.abstractr.json` marks as shared, and almost every package in this
  repo is marked that way. No test referenced the changed class or keyframes,
  so the run could not have failed because of the change. The user stopped it.
  The playbook's "check that the run can fail" rule covers only files whose
  bytes are unchanged; it says a "shared code" reason holds. That gap is in
  adtoolkit's `playbook_scope.py`, not here.
- **Building status-web to verify the change.** `panels.css` ships from `src/`
  as written, so no build step touches it.

## Research / findings

- On the machine in question, about 84,000 signposts a minute were being
  emitted. Watchdog accounted for about 10,800 of them, from committing its
  3202×1752 web view at 60 Hz. Measured with
  `/usr/bin/log show --last 60s --signpost --style ndjson` (zsh has a `log`
  builtin, so the full path is needed).
- The Overview is not fully static even with a fixed glow.
  `NextCheckCountdown` and `useNow()` re-render it once a second.
- Other endless animations in the site's CSS run only while something is
  happening: `.adh-spin` during a refresh, the auth spinner and skeleton sweep
  during sign-in.
- The live page was not inspected signed in. The conclusion about what animates
  comes from the source and the deployed stylesheet.

## Open threads

- **Review finding f1, not fixed:** `.adh-indicator-down` still animates
  `filter`, and it is used by `OfflinePanel`, the `BoardShell` top-bar pill and
  `WallboardStatus`, so a page showing something down repaints every frame on
  every tab. The reviewer's suggested fix is to animate the `opacity` of a
  pre-blurred glow layer with a fixed `filter`. The user has not ruled on it.
- Why the stuck `PerfPowerServicesSignpostReader` instance never exited was not
  established.
- Watchdog itself has no guard against a page that renders continuously. A
  four-item plan was discussed in the session and nothing was built.
- The review is recorded as `2026-11-28-live-claude-claude-opus-5-5-237d` in
  the reviews repo; devteam has not been run against it.

## Pointers

- `packages/web/packages/status-web/src/styles/panels.css`: the indicator
  rules and the comment explaining them.
- `packages/web/packages/status-web/src/styles/panels.test.ts`: the test.
- `packages/web/packages/status-web/src/components/StatusSign.tsx`: the only
  consumer of the indicator classes.
- PR #57 in this repo.
