
The suite beside the source is `dateRangePicker.test.tsx` (`packages/web/packages/ui/src/__tests__/dateRangePicker.test.tsx`); vectors derived from it name its tests.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| date-range-picker-001 | render-two-date-fields, label-from-field, label-to-field, show-controlled-value | Render with `value` of `2026-09-01` to `2026-09-30`; look the fields up by label text (test "shows both ends, each bounding the other") | Field labelled "From" has value `2026-09-01`; field labelled "To" has value `2026-09-30` |
| date-range-picker-002 | associate-labels-with-fields | Same render; query by label text "From" and "To" | Each query resolves to exactly one `input` of type `date`, the first and second field respectively |
| date-range-picker-003 | bound-from-by-min, bound-from-by-to | Render with `min` of `2026-01-01`, `max` of `2026-12-31` and the value above (test "shows both ends, each bounding the other") | "From" field has `min` of `2026-01-01` and `max` of `2026-09-30` |
| date-range-picker-004 | bound-to-by-from, bound-to-by-max | Same render | "To" field has `min` of `2026-09-01` and `max` of `2026-12-31` |
| date-range-picker-005 | bound-to-by-from, bound-from-by-to | Render with the value above and no `min` or `max` | "From" has no `min` attribute and `max` of `2026-09-30`; "To" has `min` of `2026-09-01` and no `max` attribute |
| date-range-picker-006 | report-changed-from | Change "From" to `2026-09-10` (test "reports a changed end with the other kept") | `onChange` is called with `from` of `2026-09-10` and `to` of `2026-09-30` |
| date-range-picker-007 | report-changed-to | Change "To" to `2026-09-20` (same test) | `onChange` is last called with `from` of `2026-09-01` and `to` of `2026-09-20` |
| date-range-picker-008 | ignore-cleared-field | Change "To" to the empty string (test "ignores a cleared field") | `onChange` is not called |
| date-range-picker-009 | ignore-cleared-field | Change "From" to the empty string | `onChange` is not called |
| date-range-picker-010 | pass-typed-date-through | Render with the value above and `max` of `2026-12-31`; change "To" to `2027-03-01` | `onChange` is called with `to` of `2027-03-01`; the component does not clamp it to the `max` prop |
| date-range-picker-011 | pass-typed-date-through | Render with the value above; change "From" to `2026-10-15`, later than `value.to` | `onChange` is called with `from` of `2026-10-15` and `to` of `2026-09-30` (an inverted range is reported, not rejected) |
| date-range-picker-012 | unique-field-identity | Render two pickers in one document | The four fields have four distinct ids and each label's association reaches its own field |
| date-range-picker-013 | show-controlled-value | Render with a value, then re-render with a different value | Both fields show the new value; no earlier value is retained |
| date-range-picker-014 | merge-class-name | Render with `className` of `mt-4` | The wrapper element carries `mt-4` together with `flex`, `flex-wrap`, `items-end` and `gap-3` |

