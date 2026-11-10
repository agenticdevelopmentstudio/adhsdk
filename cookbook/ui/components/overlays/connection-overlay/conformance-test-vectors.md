
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| overlay-001 | hidden-when-inactive | active=false | Component returns null; nothing rendered |
| overlay-002 | show-after-delay | active=true, wait 1200ms | Component renders in DOM after 1200ms delay |
| overlay-003 | show-after-delay (too early) | active=true, wait 500ms | Component does not render before 1200ms elapsed |
| overlay-004 | hide-immediately-on-recovery | active=true (shown), then active=false | Component is removed from the DOM without waiting out the 1200ms show-delay debounce — but not synchronously within the render that saw `active=false`: the hide runs in the passive effect that commits after that render, so a countdown tick already in flight can still fire once before the overlay disappears |
| overlay-005 | display-deploying-status-within-grace-period | active=true, elapsedMs < 90000 | Heading text is "Backend deploying" |
| overlay-006 | display-unreachable-status-after-grace-period | active=true, elapsedMs >= 90000 | Heading text is "Backend unreachable" |
| overlay-007 | display-deploying-subtext-when-deploying | active=true, elapsedMs < 90000 | Subheading text is "The backend is restarting — reconnecting automatically. This usually takes a moment." |
| overlay-008 | display-unreachable-subtext-when-unreachable | active=true, elapsedMs >= 90000 | Subheading text is "Still can't reach the backend. Retrying automatically." |
| overlay-009 | display-countdown | active=true, shown=true | Countdown displays starting at 15 and decrements by 1 every second, down through 1; 0 is never rendered |
| overlay-010 | auto-retry-on-countdown-zero | active=true, shown=true, countdown reaches 1 and ticks again | onRetry callback invoked exactly once; countdown resets to 15 without ever displaying 0 |
| overlay-011 | provide-manual-retry-button | active=true, shown=true | Button with text "Try again now" is rendered and clickable |
| overlay-012 | provide-manual-retry-button (click) | Button clicked while countdown=10 | onRetry callback invoked; countdown resets to 15 immediately |
| overlay-013 | display-detail-text-after-grace-period | active=true, elapsedMs >= 90000, detail="Network timeout" | Detail text "Network timeout" is displayed |
| overlay-014 | display-detail-text-after-grace-period (no display during deploy) | active=true, elapsedMs < 90000, detail="Error" | Detail text is not displayed |
| overlay-015 | display-detail-text-after-grace-period (null detail) | active=true, elapsedMs >= 90000, detail=null | Detail text element is not rendered |
| overlay-016 | use-aria-live-region | active=true, shown=true | Root div has role="status" and aria-live="polite" |
| overlay-017 | hide-countdown-from-screen-readers | active=true, shown=true | Countdown div has aria-hidden="true" |
| overlay-018 | prevent-interaction-with-underlying-content | active=true, shown=true, parent establishes a positioning context | Overlay element's computed `position` is `absolute` with `inset: 0` and `z-index: 50`, covering the parent's content box; a pointer event dispatched at a point within that box is captured by the overlay, not by an element beneath it |
| overlay-019 | display-spinner-icon | active=true, shown=true | An animated spinner element, 34px, colored with the blue theme token, is rendered with `aria-hidden="true"` |
| overlay-020 | visible-focus-indicator | Button rendered, no source CSS override | Button's computed `outline` is not `none`; giving it keyboard focus shows the platform's default focus ring |
| overlay-021 | display-countdown, display-unreachable-status-after-grace-period (persistence) | active=true; countdown at 8 when elapsedMs crosses 90000ms | Heading switches from "Backend deploying" to "Backend unreachable" at that tick; countdown continues from 8 — it is not reset to 15 |
| overlay-022 | show-after-delay (rapid toggle) | active: true → false → true, the second `true` arriving 500ms after the first (before the 1200ms debounce completes) | Component does not render at the original 1200ms mark; the first timer is cancelled and no state changes result from it; the component renders 1200ms after the second `true` |
| overlay-023 | respects-reduced-motion | prefers-reduced-motion: reduce, active=true, shown=true | Target behavior: the spinner's rotation is stopped. Source currently keeps the `animate-spin` class unconditionally, so this vector fails today — see Compliance |

