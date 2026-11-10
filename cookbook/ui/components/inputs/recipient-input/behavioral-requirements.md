
Unless a requirement says otherwise, every rule about "the inline input" applies equally to the separate mode's `Input` element below the recipients box — both layout modes share the same tokenize, validate, and `inputMode` logic.

- **tokenize-on-enter**: The component MUST add a new chip when the user presses Enter in the inline input, trimming whitespace and ignoring empty entries.
- **tokenize-on-comma**: The component MUST add a new chip when the user types a comma in the inline input, splitting comma-separated input into multiple chips and trimming each.
- **paste-batch-tokenization**: The component MUST apply the same comma-splitting tokenization to text inserted by paste (or any other input method) as it does to a typed comma, de-duplicating entries within the pasted batch before adding them.
- **tokenize-on-blur**: The component MUST add a new chip when focus leaves the inline input (onBlur), trimming whitespace and ignoring empty entries.
- **dedup-case-insensitive-email**: When `kind="email"`, the component MUST reject duplicate entries case-insensitively; entries `Ada@x.io` and `ada@x.io` are treated as the same recipient.
- **dedup-exact-non-email**: When `kind` is not `"email"`, the component MUST reject duplicate entries using exact string comparison.
- **validate-email**: When `kind="email"`, the component MUST validate each chip against the pattern `/^[^\s@]+@[^\s@]+\.[^\s@]+$/`; invalid chips MUST still be added but MUST render with an error appearance and `aria-invalid="true"`.
- **validate-phone**: When `kind="phone"`, the component MUST validate each chip against the pattern `/^[+]?[\d\s().-]{7,}$/`; invalid chips MUST still be added but MUST render with an error appearance and `aria-invalid="true"`. See **phone-validation-looseness** in Edge Cases: this pattern accepts punctuation/whitespace-only strings with no digits.
- **text-kind-validation**: When `kind="text"`, the component MUST NOT apply validation; all entries are accepted.
- **chip-removal-via-dismiss**: The component MUST remove a chip from the value array when its remove affordance (×) is activated. Removal filters the value array by value equality — see **duplicate-chip-removal** in Edge Cases for the effect when the array holds duplicate values.
- **backspace-removal-fused-mode**: In default (fused) mode, the component MUST remove the last chip when Backspace is pressed with an empty inline input and chips present.
- **backspace-removal-separate-mode**: In separate input mode, the component MUST NOT remove chips via Backspace when the inline input is empty.
- **input-mode-email**: When `kind="email"`, the component MUST set the inline input's `inputMode="email"`.
- **input-mode-phone**: When `kind="phone"`, the component MUST set the inline input's `inputMode="tel"`.
- **input-mode-text**: When `kind="text"`, the component MUST set the inline input's `inputMode="text"`.
- **separate-mode-layout**: When `separateInput=true`, the component MUST render in two distinct parts: a recipients box showing existing chips, and a separate text input below for adding new recipients. Chips in the recipients box remain removable `RemovableChip` elements exactly as in fused mode unless `readOnly` is also set — see Appearance.
- **readonly-mode-display**: When `readOnly=true`, the component MUST NOT render an input field; existing recipients MUST display as static, non-removable chips (Badge elements).
- **disabled-interaction**: When `disabled=true`, the component MUST render in a disabled state (reduced opacity, pointer-events-none) and MUST NOT respond to user input or trigger `onChange`. See **disabled-keyboard-removal** in Edge Cases for a caveat about keyboard-activated remove buttons.

