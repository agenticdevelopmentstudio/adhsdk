
- **render-two-date-fields**: The component MUST render two date fields, the first for the start of the range and the second for the end, in that order.
- **label-from-field**: The component MUST label the first field with the text "From".
- **label-to-field**: The component MUST label the second field with the text "To".
- **associate-labels-with-fields**: Each label MUST be programmatically associated with its own field, so that activating or querying the label text reaches that field.
- **unique-field-identity**: Each instance MUST generate a field identifier of its own, so that two pickers on one page do not share label associations.
- **show-controlled-value**: The first field MUST display `value.from` and the second field MUST display `value.to`; the component MUST NOT hold a displayed value of its own.
- **bound-from-by-min**: The first field's lower bound MUST be the `min` prop.
- **bound-from-by-to**: The first field's upper bound MUST be the current `value.to`, not the `max` prop.
- **bound-to-by-from**: The second field's lower bound MUST be the current `value.from`, not the `min` prop.
- **bound-to-by-max**: The second field's upper bound MUST be the `max` prop.
- **report-changed-from**: When the first field changes to a non-empty date, the component MUST call `onChange` once with a range whose `from` is the new date and whose `to` is the existing `value.to`.
- **report-changed-to**: When the second field changes to a non-empty date, the component MUST call `onChange` once with a range whose `to` is the new date and whose `from` is the existing `value.from`.
- **ignore-cleared-field**: When either field changes to the empty string, the component MUST NOT call `onChange`.
- **pass-typed-date-through**: The component MUST report a non-empty date exactly as the field supplied it, with no clamping to `min`, `max` or the other end and no inverted-range check.
- **merge-class-name**: The component MUST merge a caller `className` onto its wrapper element alongside its own layout classes.
- **load-as-client-module**: The module MUST be marked `"use client"`. This is verified by a static check for the directive at the top of `date-range-picker.tsx`, not by a runtime test vector.

The bounds are asymmetric by design in the source: `min` reaches only the first field and `max` reaches only the second. Together with the cross bounds they keep both fields inside `min` to `max` and keep `from` from passing `to`, but only for picks made in the browser's own picker.

