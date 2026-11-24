
| ID | Requirement | Input | Expected |
|----|-------------|-------|----------|
| T1 | tokenize-on-enter | Type `ada@x.io` and press Enter in fused mode | Neutral chip `ada@x.io` added to value; input clears |
| T2 | tokenize-on-comma | Type `ada@x.io`, then a comma, then `grace@x.io`, then a comma, in the inline input | `ada@x.io` is added on the first comma and `grace@x.io` on the second; two chips in total; input clears after each |
| T3 | paste-batch-tokenization | Paste `a@x.io, A@x.io` into the inline input with `kind="email"` | One chip `a@x.io` added; the pasted duplicate (`A@x.io`, same email case-insensitively) is dropped before being added; input clears |
| T4 | tokenize-on-blur | Type `  ada@x.io  ` and blur the input | Trimmed chip `ada@x.io` added; input clears |
| T5 | dedup-case-insensitive-email | `kind="email"`: add `Ada@x.io` then attempt to add `ada@x.io` | Second entry rejected; one chip remains; input still clears (see Edge Cases) |
| T6 | dedup-exact-non-email | `kind="text"`: add `Ada` then attempt to add `ada` | Both chips added (exact match required) |
| T7 | validate-email | `kind="email"`: add `bad@` | Chip rendered with error appearance + `aria-invalid="true"` but still in value |
| T8 | validate-email | `kind="email"`: add `ada@x.io` | Chip rendered with neutral appearance; no `aria-invalid` |
| T9 | validate-phone | `kind="phone"`: add `12345` (too short) | Chip rendered with error appearance + `aria-invalid="true"` but still in value |
| T10 | validate-phone | `kind="phone"`: add `+1 (555) 123-4567` | Valid; chip rendered neutral |
| T11 | text-kind-validation | `kind="text"`: add `@#$%^` | No validation error; chip neutral |
| T12 | chip-removal-via-dismiss | Fused mode with chips present; click × on a chip | That chip removed from value |
| T13 | chip-removal-via-dismiss | Tab to a chip's remove button and press Enter (or Space) | Same removal as a click; the button is reachable and activatable by keyboard |
| T14 | chip-removal-via-dismiss | `value=["ada@x.io","ada@x.io"]` seeded directly by the parent, `kind="email"`; click × on either chip | Both chips are removed — value becomes `[]` (removal filters by value, not index) |
| T15 | backspace-removal-fused-mode | Fused mode with chips and empty input; press Backspace | Last chip removed |
| T16 | backspace-removal-separate-mode | Separate mode with chips and empty input; press Backspace | Input text behavior only; no chip removed |
| T17 | input-mode-email | `kind="email"` | Inline input has `inputMode="email"` |
| T18 | input-mode-phone | `kind="phone"` | Inline input has `inputMode="tel"` |
| T19 | input-mode-text | `kind="text"` (or unspecified) | Inline input has `inputMode="text"` |
| T20 | separate-mode-layout | `separateInput=true` | Component renders a recipients box and a separate input below it |
| T21 | readonly-mode-display | `readOnly=true` with existing recipients | Recipients display as static Badge chips; no input field shown; no remove control on any chip |
| T22 | readonly-mode-display | `readOnly=true` with existing recipients | The rendered output contains no `<input>` and no `<button>`; `onChange` is never called |
| T23 | disabled-interaction | `disabled=true`; click a chip's remove control or type in the input | Component appears grayed out; pointer interaction and typing are inert; `onChange` is not called |
| T24 | separate-mode-layout | Separate mode with an empty `value` | The recipients box shows "No recipients yet" |
| T25 | tokenize-on-enter | Fused mode with a `placeholder`: render with an empty `value`, then with one chip | The inline input shows the placeholder when `value` is empty and shows none once a chip exists |
| T26 | readonly-mode-display | `separateInput=true` and `readOnly=true` with recipients | Recipients box shows static Badge chips; no input below it |
| T27 | dedup-case-insensitive-email | `kind="email"` with `ada@x.io` already present: type `Ada@x.io` then a comma, and separately type `Ada@x.io` and blur | No chip is added in either case; `onChange` is not called; the input clears |
| T28 | input-mode-text | No `placeholder` prop, empty `value`, each `kind` | Placeholder is `Add email…` for email, `Add phone…` for phone, `Add…` for text |
