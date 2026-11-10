
1. **Show delay (1200ms)**
   **Decision**: Debounce the overlay's appearance by 1200ms after `active` becomes `true`, and skip that debounce entirely — hiding as soon as the recovery effect runs — the instant `active` becomes `false`.
   **Rationale**: This absorbs brief network hiccups and momentary reconnects without flashing an alarming overlay at the user; hiding skips the debounce on recovery so the overlay never lingers past the outage, even though the hide itself lands on the next commit (a passive effect), not synchronously within the render that saw `active=false` (see hide-immediately-on-recovery). 1200ms is a source constant — the code comments describe intent ("don't flash on a momentary blip") but the exact value's derivation is not documented in source and should be treated as unverified rather than tied to any specific deploy-restart measurement.
   **Approved**: pending

2. **Grace period (90 seconds)**
   **Decision**: Frame outages under 90 seconds as "Backend deploying" (calm, expected) and outages at or past 90 seconds as "Backend unreachable" (explicit acknowledgment).
   **Rationale**: A redeploy briefly drops the connection; framing that as deploying avoids alarming the user during an expected, short gap, while a longer outage warrants a plainer, less reassuring message. Like the show delay, 90,000ms is a source constant with no documented derivation in source — treat its rationale as unverified rather than confirmed against real backend restart timings.
   **Approved**: pending

3. **Retry countdown (15 seconds)**
   **Decision**: Use a fixed 15-second auto-retry cadence, independent of the consuming application's own poll clock.
   **Rationale**: A fixed local countdown always counts cleanly down to a real retry without drift or desynchronization from an external clock; 15 seconds balances frequent attempts (low user wait time) against backend load (not hammering a recovering service).
   **Approved**: pending

4. **Countdown persists across heading changes**
   **Decision**: The countdown continues running when the outage crosses the 90-second grace period and the heading switches from "deploying" to "unreachable" — it is not reset by the heading change.
   **Rationale**: Resetting the countdown at the same moment the heading changes would be visually jarring and would wrongly suggest that retries had restarted, when in fact they have been continuing steadily throughout.
   **Approved**: pending

5. **Detail text hidden during deploy phase**
   **Decision**: Hide the `detail` text during the deploying phase; show it only once the grace period has expired.
   **Rationale**: During a brief, expected deploy window, a technical error string is distracting and irrelevant noise; once the outage is plainly abnormal, the detail becomes useful context.
   **Approved**: pending

6. **ref-based callback storage (onRetryRef)**
   **Decision**: Store `onRetry` in a ref (`onRetryRef`), updated on every render, rather than including it in the tick effect's dependency array.
   **Rationale**: A consumer passing a new inline callback identity on every render is common; listing `onRetry` as a dependency would re-run the effect and reset the countdown on every parent re-render, so the 15s auto-retry would never actually fire.
   **Approved**: pending

7. **aria-hidden on countdown and spinner**
   **Decision**: Mark both the countdown and the spinner `aria-hidden="true"`.
   **Rationale**: The countdown updates every second and would spam a screen reader if announced; the spinner is purely decorative. The heading and subheading, inside the `aria-live="polite"` region, already convey all necessary state.
   **Approved**: pending

8. **Absolute positioning with inset: 0**
   **Decision**: Position the overlay with `inset: 0` (shorthand for top/right/bottom/left) rather than four longhand declarations, covering the parent container's content box.
   **Rationale**: `inset: 0` is more concise and maintainable than specifying each side individually; the overlay's parent must establish a positioning context (`position: relative` or equivalent) for this to cover it correctly — the overlay covers its containing block, not necessarily the browser viewport.
   **Approved**: pending

9. **App-agnostic color tokens, except button text and shadow**
   **Decision**: Colors reference ADH theme tokens (`var(--color-apt-*)`) for every surface, border, and text color, so the component adapts to the consuming application's theme without modification — except the button's text color (hard-coded `white`) and the card's drop shadow (hard-coded `rgba(0,0,0,0.35)`), which are fixed values rather than tokens.
   **Rationale**: Token-based colors let the overlay track the app's light/dark theme; the button text and shadow are left as fixed values in source rather than tokenized, narrowing this decision's scope to "all colors except those two."
   **Approved**: pending

10. **Obscuring background (90% opacity + blur)**
    **Decision**: Make the overlay's background 90% opaque with a 3px blur.
    **Rationale**: A transparent overlay would blur the distinction between "overlay present" and "content behind it"; a fully opaque one would hide context entirely. 90% opacity with blur keeps the overlay the clear visual focus while still hinting at the content underneath.
    **Approved**: pending

