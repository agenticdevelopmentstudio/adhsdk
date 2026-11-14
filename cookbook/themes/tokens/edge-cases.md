
- **Empty or no-match input**: `splitImports("")` MUST return no imports and an empty `rest`; `parseRootProps("")` MUST return an empty Map. Neither throws.
- **Non-string input**: Both functions are typed to take a `string`; the source does no runtime check, so a non-string argument is a caller error outside the contract.
- **String-form imports**: An `@import "x.css"` rule is left in `rest` and not reported (MUST). The imports of the generated themes use the `url(...)` form, so this is the contract rather than a defect.
- **Imports inside comments or other text**: A matching rule is removed and reported wherever it occurs (MUST), with no awareness of comments.
- **Last declaration without a semicolon**: Dropped silently (MUST). Generated theme CSS ends every declaration with `;`; free-form CSS from the editor may not, and its last property is then missing from the map.
- **Value containing a semicolon**: Cut at the first `;` (MUST). A data URL or other value with an interior semicolon is truncated and the remainder discarded.
- **Value containing a closing brace**: The block ends at the first `}` anywhere inside it, including inside a quoted string or a function value, so later declarations are lost (MUST).
- **Duplicate property names**: The last value wins and the first position is kept (MUST).
- **Whitespace-only value**: Stored as the empty string (MUST).
- **Multiple `:root` blocks**: Only the first is read (MUST); the comment on the block pattern says the first `:root` block of a generated theme is its token block and what follows is theme-independent.
- **Concurrent access**: Not a concern; the functions are synchronous and pure, and JavaScript runs them one at a time. The module-level regular expressions carry the global flag but are used only through `replace` and `matchAll`, which do not depend on a prior match position.
- **Error states, offline and cancellation**: Not applicable; there is no I/O, no dependency that can fail and no long-running work to cancel. Malformed CSS never raises; it yields fewer entries.
- **Very large input**: The source sets no size limit and no timeout; the patterns are single linear scans.

