
- **input-type**: Component MUST support specifying the input type (text, email, password, number, etc.) so the underlying platform control applies the type-appropriate keyboard, masking, and validation behavior.
- **placeholder**: Component MUST display placeholder text when the field is empty, styled as visually de-emphasized (dimmed) text distinct from entered content.
- **autofill-token**: Component MUST accept an autofill-token prop (HTML `autocomplete`) and, when no valid token is provided (absent, explicitly `undefined`, or `"off"`), apply the following opt-out attributes so no supported password manager offers to fill or save the field: `autocomplete="off"`, `data-form-type="other"` (Dashlane), `data-1p-ignore` (1Password), `data-lpignore` (LastPass), `data-bwignore` (Bitwarden), `data-protonpass-ignore` (Proton Pass). When a real token is provided, none of these opt-out attributes are applied and the token passes through unchanged.
- **selection-styling**: Component MUST style user-selected/highlighted text with a tinted background distinct from the field's own background.
- **dom-prop-forwarding**: Component MUST accept and forward all standard native text-input props (value, onChange, onBlur, etc.) to the underlying platform control.
- **field-shell-styling**: Component MUST apply the same base field shell styling (rounded corners, border, background) used by sibling field controls, so all field-shaped controls stay visually consistent.
- **width-constraint**: Component MUST fill its container's available width without overflowing a flex or grid layout when its content is long.
- **classname-merging**: Component MUST accept caller-supplied style overrides and merge them with the component's internal styling, with the caller's styling taking precedence.

