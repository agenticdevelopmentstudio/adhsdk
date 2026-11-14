
- **Empty string error**: `error=""` (falsy) is treated as no error; hint is shown if present. Empty strings are falsy in JavaScript.
- **Empty string hint**: `hint=""` (falsy) is treated as no hint; nothing is rendered if error is also absent.
- **Zero or false**: `error={0}` or `error={false}` are falsy and treated as no error; same for hint. See **supports-react-node-content**.
- **Null/undefined**: Both are falsy and result in no error or hint being shown.
- **className merging collision**: If `className` contains a utility class that conflicts with a default class in the same category (e.g., a caller passing `text-blue-500` when the default is `text-apt-red`), the merge utility resolves the conflict by last-wins — the caller's class is applied after the defaults and therefore takes effect — not by CSS specificity.
- **errorId set but hint renders**: If `errorId` is provided while `error` is falsy, the hint renders instead and carries no `id` (see **error-id-only-on-error**, vector field-footnote-006). A consumer that unconditionally wires a control's `aria-describedby` to `errorId` will then point at an id that does not exist in the DOM whenever only the hint is showing; consumers should apply `aria-describedby={errorId}` only while `error` is actually present.

