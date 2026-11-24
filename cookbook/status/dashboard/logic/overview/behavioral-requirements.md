
### Types

- **indicator-state-union**: The sign-state value MUST be exactly one of `"ok"`, `"warn"` or `"down"`.
- **indicator-shape**: An indicator value MUST carry a sign state and a count (a whole number).

### Wire-indicator translation map

- **indicator-map-values**: The wire-indicator translation map MUST map `operational` to `"ok"`, `degraded` to `"warn"` and `outage` to `"down"`.
- **indicator-map-exhaustive**: The wire-indicator translation map MUST have exactly the three keys `degraded`, `operational` and `outage` — one per member of the server's wire-level indicator vocabulary, with no extras.
- **indicator-map-sole-translation**: The wire-indicator translation map MUST be the only place that translates the wire indicator into a sign state; the doc comment names it "The ONLY translation between the two."

### Activity-window-caption operation

- **window-signature**: The activity-window-caption operation MUST take a window-start time and a window-end time and MUST return a text caption.
- **window-hours**: The operation MUST compute the span in hours as the duration between the two times divided by 3,600,000 (milliseconds per hour), rounded to the nearest whole number, with a minimum of 1.
- **window-days**: When the hour count is 48 or more and is a whole multiple of 24, the operation MUST return the caption formed by dividing the hour count by 24 followed by the letter `d` (for example `"7d"`).
- **window-hours-label**: Otherwise the operation MUST return the caption formed by the hour count followed by the letter `h` (for example `"24h"`, `"47h"`).
- **window-min-one-hour**: A window shorter than 30 minutes, zero, or negative MUST be captioned `"1h"`, never `"0h"`.
- **window-server-boundary**: The caller MUST derive both bounds from the board's own reported activity window rather than a hardcoded span; the doc comment forbids a hardcoded caption because the server owns the window's length.

### Headline operation

- **headline-signature**: The headline operation MUST take a sign state and a count and MUST return a text headline.
- **headline-ok**: For sign state `"ok"` the operation MUST return `"ALL SYSTEMS OPERATIONAL"`, ignoring count.
- **headline-warn-singular**: For sign state `"warn"` and count `1` it MUST return `"1 SERVICE NEEDS ATTENTION"`.
- **headline-warn-plural**: For sign state `"warn"` and any other count it MUST return the count followed by `" SERVICES NEED ATTENTION"`.
- **headline-down-singular**: For sign state `"down"` and count `1` it MUST return `"1 PROBLEM"`.
- **headline-down-plural**: For sign state `"down"` and any other count it MUST return the count followed by `" PROBLEMS"`.
- **headline-single-wording**: Every surface that announces the sign's headline (hero sign, top-bar pill accessible name, wallboard pill) MUST obtain it from the headline operation, so they cannot word it differently. An "unknown" state is outside the sign-state vocabulary; callers word that case themselves (for example, showing "Status unknown" or "UNKNOWN").

### Still-unresolved operation

- **unresolved-signature**: The still-unresolved operation MUST take an activity row and a list of the board's current problems (each carrying a target and an onset time) and MUST return true or false.
- **unresolved-server-verdict**: A row whose `unresolved` field is not `true` MUST NOT be revived: the operation returns `false`. It never raises a row the server judged resolved.
- **unresolved-held-open**: For a row with `unresolved: true` and a non-empty `heldOpenBy` list, the operation MUST return true only while some current problem has the row's own target and an onset time listed in `heldOpenBy`. It only looks those problems up and judges nothing itself.
- **unresolved-in-flight**: A row with `unresolved: true` and an empty `heldOpenBy` (a row in flight) MUST keep the server's verdict and return true.
- **unresolved-no-held-open**: A row with `unresolved: true` and no `heldOpenBy` (a backend that sends none) MUST keep the server's verdict and return true.

### Purity and concurrency

- **pure-functions**: Every exported operation MUST be synchronous and pure: no I/O, no logging, no mutation of its inputs, no module state. The result depends only on the arguments.
- **no-throw**: No operation throws on inputs of its declared shapes; malformed values degrade as described under Edge Cases rather than raising.
- **single-threaded**: The module holds no state, so calls cannot interleave and no ordering rule is needed.

