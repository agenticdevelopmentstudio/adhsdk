All 24 vectors are tested in the `BarList` block of `src/__tests__/trendChart.test.tsx`, one `it` per vector with the vector id at the start of its title; the items US 100, SG 50, CN 10 are the shared fixture. jsdom computes no layout or Tailwind styles, so the opacity vectors check the `opacity-55` class and the bar vectors check the inline `width` and `min-width` styles.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| bl-001 | initial-row-limit, expand-control-presence, expand-opens-in-place, expand-label, expand-collapse (test: opens what it leaves out, and closes it again) | The three items, `maxItems=2`; read; click "Show all 3"; click "Show fewer" | CN is absent; after "Show all 3" CN is present; after "Show fewer" CN is absent again |
| bl-002 | expand-control-presence (test: offers nothing to open when every row fits) | The three items, `maxItems=Infinity`, no `onSelect` | CN is present; the document has no button |
| bl-003 | name-wraps (test: lets a long name wrap rather than cutting it off) | One item named `/a/very/long/path/that/would/not/fit/in/a/narrow/panel`, value 1 | The name element's class list does not contain `truncate` |
| bl-004 | rows-plain-without-select (test: is plain text until it can do something) | The three items, default `maxItems`, no `onSelect` | The document has no button |
| bl-005 | rows-are-buttons-with-select, select-reports-name, pressed-state-exposed (test: reports the row chosen, and marks it) | The three items, `selected="SG"`, an `onSelect` that records its argument; click the US row | The SG row button has `aria-pressed` true; `onSelect` was called with "US" |
| bl-006 | row-order | Items [CN 10, US 100, SG 50] | Rows read CN, US, SG, top to bottom |
| bl-007 | list-accessible-name | `ariaLabel="Top countries"`, the three items | The list's accessible name is "Top countries" |
| bl-008 | row-value-text, default-value-format | Items [{A, 9999}, {B, 12500}], no `formatValue` | Value texts read "9,999" and "12.5K" |
| bl-009 | detail-replaces-value | Item {A, 5, detail "12 issues · 340 events"}, a `formatValue` that records calls | The row shows "12 issues · 340 events"; `formatValue` was not called for that row |
| bl-010 | detail-replaces-value (empty string) | Item {A, 5, detail ""} | The value text is empty; the formatted value "5" is not shown |
| bl-011 | bar-length-proportional | Items [US 100, SG 50, CN 10] | Bar widths 100%, 50%, 10% |
| bl-012 | bar-length-proportional (hidden row counts) | Items [US 100, SG 50, CN 10], `maxItems=1` | The one shown row's bar is 100%; after opening, SG is 50% (the maximum was never computed from the shown rows only) |
| bl-013 | bar-zero-maximum | Items [A 0, B 0] | Both bars have width 0% |
| bl-014 | bar-minimum-width | Items [US 100000, CN 1] | The CN bar has a 2px minimum width |
| bl-015 | bar-minimum-width (zero) | Items [US 100, ZZ 0] | The ZZ bar has a minimum width of 0 |
| bl-016 | bar-color | `color` omitted; then `color="red"` | Bars use `var(--color-apt-cat-blue)`; then red |
| bl-017 | bar-decorative | Any non-empty list | Each bar's wrapper has `aria-hidden` true |
| bl-018 | empty-state | `items=[]`, `emptyLabel` omitted; then `emptyLabel="No referrers"` | "Nothing to show." with no list and no button; then "No referrers" |
| bl-019 | dim-unselected-rows | `onSelect` given, `selected="SG"` | US and CN row buttons are at 55% opacity; SG is not |
| bl-020 | dim-unselected-rows (no selection) | `onSelect` given, `selected` omitted | No row button is dimmed; all have `aria-pressed` false |
| bl-021 | expand-state-exposed | Collapsed, then expanded | Expand button `aria-expanded` is false, then true |
| bl-022 | expand-state-local | `maxItems=2`, expand, then rerender with a different `items` array of 3 items | The list still shows every item, and the button still reads "Show fewer" |
| bl-023 | class-name-target | `className="x"`, with items; then with `items=[]` | The outermost element carries "x" in both cases |
| bl-024 | select-reports-name | The SG row is already selected; click the SG row | `onSelect` is called once with "SG" |

