
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| guard-001 | block-beforeunload | Guard armed (`when=true`); user presses Cmd+R or closes tab | Browser's native "Leave site?" prompt appears; page does not reload |
| guard-002 | prompt-anchor-navigation | Guard armed; user left-clicks an anchor to `/other?foo=bar` on same origin | `UnsavedChangesAlert` opens; page stays at current URL until user chooses |
| guard-003 | skip-marked-anchors | Guard armed; anchor has `GUARDED_NAV_ATTR` attribute | No confirmation from guard; anchor's own handler runs uninterrupted |
| guard-004 | skip-same-page-links | Guard armed; user clicks `href="#section"` on same page | Navigation completes without confirmation; hash changes |
| guard-005 | skip-cross-origin | Guard armed; user clicks anchor to `https://example.com` | No confirmation from guard; browser handles cross-origin unload via `beforeunload` |
| guard-006 | guard-back-button | Guard armed as primary; user presses browser Back button | Sentinel same-URL history entry is consumed; `UnsavedChangesAlert` opens |
| guard-007 | call-on-navigate | Guard armed; user confirms discard on anchor to `/next`; `onNavigate` is provided | `onNavigate("/next")` is called with the target href |
| guard-008 | call-on-navigate | Guard armed; user confirms discard on anchor to `/next`; `onNavigate` is not provided | `window.location.assign("/next")` is called |
| guard-009 | approve-briefly | User confirms navigation; page stays mounted with dirty state | `beforeunload` does not prompt during the 1000ms approval window |
| guard-010 | prompt-after-approval | `approveNavigation()` called (prior guard); guard with `when=true` sees a navigation | No confirmation is raised; navigation proceeds |
| guard-011 | prevent-default | Guard armed; user clicks anchor | `e.preventDefault()` is called; other click handlers still execute; `e.stopPropagation()` is never called |
| guard-012 | prompt-anchor-navigation | Guard armed; a same-origin anchor click event already has `defaultPrevented === true` (e.g. another capture-phase listener intercepted it first) | `onClick` returns immediately; no confirm is raised by this guard |
| guard-013 | clear-sentinel-on-back | Primary guard armed; user presses Back (consumes sentinel); user confirms discard | The guard issues a real second `window.history.back()`; pressing Back again afterward does not re-trigger this guard's confirm (no stale sentinel remains armed at the prior URL) |
| guard-014 | update-sentinel-on-rearm | Secondary guard armed at URL A; primary guard disarms (unregisters) while this guard is still at URL A; membership-change subscription fires | This guard becomes primary and pushes a fresh same-URL history entry — `history.length` increases by one immediately after the disarm |
| guard-015 | guard-back-button | Primary and a non-primary guard both armed, both with popstate listeners; user presses browser Back | Only the primary's popstate handler proceeds past the primary check and consumes the sentinel; the non-primary's popstate handler returns early and raises no confirm |
| guard-016 | block-beforeunload | Confirm dialog open (anchor navigation pending); `when` transitions from true to false before the user responds | Effect cleanup removes the `beforeunload`/`popstate`/`click` listeners and unregisters from the registry; the alert stays open (`confirm` state is untouched) and the user's Discard/Stay choice still resolves normally |
| guard-017 | register-with-registry | A registry-awaited confirm is pending (`requestConfirm()`'s promise unresolved, e.g. from `router.push()` or a popstate) when a same-origin anchor is then clicked | `setConfirm` overwrites the pending state with the anchor's `{href}`; the earlier `resolve` is never called, so the earlier caller's awaited `confirmNavigation()` never settles |
| guard-018 | prompt-anchor-navigation | Guard armed; anchor has `target="_other"` | `onClick` returns early on the target check; browser opens in the specified target without a confirm |
| guard-019 | prompt-anchor-navigation | Guard armed; user Cmd-clicks (or Ctrl/Shift/Alt) a same-origin anchor | `onClick` returns early on the modifier-key check; browser opens the link in a new tab without a confirm |
| guard-020 | guard-back-button | Primary guard armed; user presses Back (sentinel consumed, confirm raised); user chooses Stay | `window.history.pushState` re-pushes a same-URL entry and the sentinel is set back to the current URL, so a second Back press is required to leave and re-raises the same confirm |

