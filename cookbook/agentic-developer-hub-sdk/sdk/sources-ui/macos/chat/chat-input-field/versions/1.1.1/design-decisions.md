
**Decision**: The web component wraps the input in a `<form>` element to prevent iOS Safari from classifying a lone input field against the entire document for autofill purposes.
**Rationale**: A bare input without a form is scoped globally and can trigger contact autofill if the page contains other contact-related content; a form of its own gives the classifier a one-field form that asks for nothing.
**Approved**: pending

**Decision**: The Enter key handler and the send button both trigger form submission, giving keyboard and pointer sends one code path.
**Rationale**: Two independent send paths — an Enter handler calling send logic directly, and a button `onClick` calling it again — could diverge over time; routing both through the same `<form>` submit prevents that.
**Approved**: pending

**Decision**: Whitespace is trimmed only at the point of send, not as the user types.
**Rationale**: The input field shows exactly what the user typed, including leading/trailing spaces, so the user can see what they are about to send; trimming happens once, right before the message leaves the component.
**Approved**: pending

**Decision**: Multiple password-manager opt-out attributes are set (`data-1p-ignore`, `data-lpignore`, `data-bwignore`, `data-protonpass-ignore`), alongside Dashlane's `data-form-type="other"`.
**Rationale**: Each password manager reads its own ignore signal and ignores the others'; broad compatibility requires setting all of them rather than relying on a single standard.
**Approved**: pending

**Decision**: The block caret is implemented as a macOS-specific affordance, drawn by a custom `CALayer` on top of `ChatInputField` (AppKit).
**Rationale**: Terminal themes (old-school-terminal, etc.) want a block caret to match CRT aesthetics; AppKit's field editor does not expose insertion-point-shape customization (`drawInsertionPoint(in:color:turnedOn:)` is not called for a field editor on current macOS), so the caret has to be drawn as the field's own layer instead. Other platforms use their native carets.
**Approved**: pending

**Decision**: On web, the input carries both a `name="message"` attribute and an `aria-label="Message"`; the placeholder is not treated as a substitute for either.
**Rationale**: `name` gives the input identity within its `<form>` for submission context and is unrelated to the DOM-based autofill opt-outs the form's own attributes provide (see **opt-out-ios-autofill**); `aria-label` gives screen readers a stable label that does not depend on the field being empty, unlike a placeholder.
**Approved**: pending

