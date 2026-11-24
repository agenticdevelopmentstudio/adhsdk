
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| overlay-001 | hidden-when-inactive | active=false | Component returns null; nothing rendered |
| overlay-002 | show-after-delay | active=true, wait 1200ms | Component renders in DOM after 1200ms delay |
| overlay-003 | show-after-delay (too early) | active=true, wait 500ms | Component does not render before 1200ms elapsed |
| overlay-004 | hide-immediately-on-recovery | active=true (shown), then active=false; flush effects | Component is removed from the DOM without waiting out the 1200ms show-delay debounce |
| overlay-005 | display-deploying-status-within-grace-period | active=true; advance fake timers 1200ms + 1000ms | Heading text is "Backend deploying" |
| overlay-006 | display-unreachable-status-after-grace-period | active=true; advance fake timers 1200ms + 90000ms | Heading text is "Backend unreachable" |
| overlay-007 | display-deploying-subtext-when-deploying | active=true; advance fake timers 1200ms + 1000ms | Subheading text is "The backend is restarting — reconnecting automatically. This usually takes a moment." |
| overlay-008 | display-unreachable-subtext-when-unreachable | active=true; advance fake timers 1200ms + 90000ms | Subheading text is "Still can't reach the backend. Retrying automatically." |
| overlay-009 | display-countdown | active=true, shown=true | Countdown displays starting at 15 and decrements by 1 every second, down through 1; 0 is never rendered |
| overlay-010 | auto-retry-on-countdown-zero | active=true, shown=true, countdown reaches 1 and ticks again | onRetry callback invoked exactly once; countdown resets to 15 without ever displaying 0 |
| overlay-011 | provide-manual-retry-button | active=true, shown=true | Button with text "Try again now" is rendered and clickable |
| overlay-012 | provide-manual-retry-button (click) | Button clicked while countdown=10 | onRetry callback invoked; countdown resets to 15 immediately |
| overlay-013 | display-detail-text-after-grace-period | active=true, detail="Network timeout"; advance fake timers 1200ms + 90000ms | Detail text "Network timeout" is displayed |
| overlay-014 | display-detail-text-after-grace-period (no display during deploy) | active=true, detail="Error"; advance fake timers 1200ms + 1000ms | Detail text is not displayed |
| overlay-015 | display-detail-text-after-grace-period (null detail) | active=true, detail=null; advance fake timers 1200ms + 90000ms | Detail text element is not rendered |
| overlay-016 | use-aria-live-region | active=true, shown=true | Root div has role="status" and aria-live="polite" |
| overlay-017 | hide-countdown-from-screen-readers | active=true, shown=true | Countdown div has aria-hidden="true" |
| overlay-018 | prevent-interaction-with-underlying-content | active=true, shown=true, parent establishes a positioning context | Overlay element's computed `position` is `absolute` with `inset: 0` and `z-index: 50`, covering the parent's content box; a pointer event dispatched at a point within that box is captured by the overlay, not by an element beneath it |
| overlay-019 | display-spinner-icon | active=true, shown=true | A `Loader2` spinner element, 34px, colored `var(--color-apt-blue)`, is rendered with `aria-hidden="true"` |
| overlay-020 | visible-focus-indicator | Button rendered, no source CSS override | Button's computed `outline` is not `none`; giving it keyboard focus shows the platform's default focus ring |
| overlay-021 | display-countdown, display-unreachable-status-after-grace-period (persistence) | active=true; advance fake timers 1200ms, then 89 ticks (heading still "Backend deploying", countdown 1), then the 90th tick (outage clock reaches 90000ms), then 7 more ticks | Heading switches from "Backend deploying" to "Backend unreachable" at tick 90; the countdown follows its own 15-second cycle (auto-retry fired at ticks 15, 30 … 90) and shows 8 at tick 97 — the status switch does not reset it |
| overlay-022 | show-after-delay (rapid toggle) | active: true → false → true, the second `true` arriving 500ms after the first (before the 1200ms debounce completes) | Component does not render at the original 1200ms mark; the first timer is cancelled and no state changes result from it; the component renders 1200ms after the second `true` |
| overlay-023 | respects-reduced-motion | active=true, shown=true; inspect the spinner's classes (jsdom evaluates no media query) | The spinner is `animate-spin motion-reduce:animate-none`, so its rotation stops under reduced motion; the test asserts the utility class |
| overlay-024 | no-retry-after-recovery | active=true, shown; set active=false and fire one pending 1s tick before effects flush | `onRetry` is not called after `active` is false: the tick returns early because `activeRef` already reads false |
| overlay-025 | contain-focus | active=true, shown; press Tab repeatedly from a control behind the overlay | Focus moves to "Try again now" on show; Tab and Shift+Tab wrap among the card's focusables; on hide, focus returns to the prior element if it is still connected and focus is on `body` |
