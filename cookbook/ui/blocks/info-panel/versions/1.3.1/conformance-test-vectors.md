
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | titled-header | `title="Fleet"`, `icon=<I/>`, `titleAfter=<Copy/>` | header shows icon, then "Fleet", then the copy control |
| T2 | count-when-positive | `count={12}` | "12" rendered after the title |
| T3 | count-when-positive | `count={0}` (or omitted) | no count rendered |
| T4 | header-slot-placement | `center=<Bar/>`, `actions=<Gear/>` | center in the centered slot, actions in the right slot |
| T5 | actions-right-justified-without-center | `actions=<Gear/>`, no `center` | the actions block's right edge equals the header's inner right edge (no center spacer needed to achieve it) |
| T6 | shared-header-height | render two panels | both headers have `min-height: 41px` and align — **Playwright/E2E**: jsdom has no real layout to assert alignment against |
| T7 | content-sized-by-default | default (`scroll` unset) | outer `flex: 0 0 auto`; body has no `overflow-y-auto` |
| T8 | fill-and-scroll-on-scroll | `scroll` with overflowing content | outer `flex: 1 1 0`; body `overflow-y-auto` and scrolls — **Playwright/E2E**: jsdom does not lay out or scroll content |
| T9 | body-ref-exposure | pass a `bodyRef` | the ref resolves to the scrolling body element |
| T10 | label-region | `title="Fleet"`, no `ariaLabel` | `<section aria-label="Fleet">` |
| T11 | label-region | non-string `title`, `ariaLabel="Fleet"` | `<section aria-label="Fleet">` |
| T12 | mode-default-padding | `scroll` vs card, no `bodyPadding` | body padding `8px 16px 10px` (scroll) vs `12px 16px` (card) |
| T13 | layout-prop-passthrough | `flex="2 1 0"`, `maxHeight={400}` | outer style carries that flex and `max-height: 400px` |
| T14 | host-attribute-passthrough | `data-testid="panel"`, `data-kind="monitor"` | outer `<section>` carries both attributes; `aria-label` still defaults from `title` |
| T15 | host-attribute-passthrough | `title="Fleet"` (string), rest `aria-label="FromRest"`, `ariaLabel="Explicit"` | `<section aria-label="Explicit">` — the `ariaLabel` prop wins over both the rest `aria-label` and the string `title` |
| T16 | host-attribute-passthrough | `title="Fleet"` (string), rest `aria-label="FromRest"`, no `ariaLabel` prop | `<section aria-label="FromRest">` — the rest attribute wins over the string `title` fallback when `ariaLabel` is absent |
| T17 | count-when-positive | `count={-3}` | no count rendered (negative is treated as not positive) |
| T18 | label-region | non-string `title`, no `ariaLabel` | `<section>` has no `aria-label` — the known gap (see Edge Cases, "Non-string title") |

