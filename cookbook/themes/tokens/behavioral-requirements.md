
### Public surface

- **exports**: The module MUST export `ThemeDelta`, `splitImports` and `parseRootProps`, and MUST export nothing else.
- **theme-delta-shape**: `ThemeDelta` MUST be `Record<string, string>`, a map from custom-property name to value; the module attaches no validation to it.
- **pure**: Both functions MUST be pure: they MUST NOT read or write the DOM, storage, the network or module state, and the same input MUST give the same output.
- **no-throw**: Neither function MUST throw on any string input; input that does not match yields an empty result, never an error.

### splitImports

- **imports-pattern**: `splitImports` MUST recognise an import rule as `@import`, whitespace, `url(`, optional whitespace, an optional single or double quote, the href, the same quote again, optional whitespace, `)`, optional whitespace and an optional `;`.
- **imports-href**: The href captured MUST be the text between the quotes (or between the parentheses when unquoted), up to the first `'`, `"` or `)`; for an unquoted href, any whitespace before the closing parenthesis is part of the captured text.
- **imports-order**: The returned `imports` array MUST list hrefs in the order the rules appear in the CSS, with duplicates kept.
- **imports-removed**: Every matched rule, including the whitespace and the `;` that follow its closing parenthesis, MUST be replaced by an empty string in `rest`; all other text, including whitespace before the rule, MUST be left unchanged.
- **imports-url-only**: The string form of an import (an `@import` followed by a quoted string rather than `url(`) MUST NOT be matched: it stays in `rest` and adds nothing to `imports`.
- **imports-none**: When no rule matches, `splitImports` MUST return an empty `imports` array and a `rest` equal to the input.
- **imports-everywhere**: Matching MUST NOT depend on position or context: a rule is removed wherever it appears in the string, including inside a comment.

### parseRootProps

- **root-block-first**: `parseRootProps` MUST read only the first match of `:root`, optional whitespace, `{`, any run of characters that are not `}`, `}`; later `:root` blocks MUST be ignored.
- **root-block-ends-at-brace**: The block MUST end at the first `}` after the opening `{`; a declaration after that brace is not read.
- **root-block-anywhere**: The block match MUST NOT be anchored, so a `:root` that is part of a longer selector (for example `html:root`) is matched too.
- **root-missing**: When the CSS has no `:root` block, `parseRootProps` MUST return an empty `Map`.
- **prop-pattern**: A custom property MUST be recognised as `--`, one or more word characters or hyphens, optional whitespace, `:`, optional whitespace, a value of one or more characters other than `;`, and a terminating `;`. Word characters are ASCII letters, digits and underscore.
- **prop-name-verbatim**: The map key MUST be the name including its leading `--`, with its case unchanged.
- **prop-value-trimmed**: The map value MUST be the captured value with leading and trailing whitespace trimmed; interior whitespace and newlines MUST be kept.
- **prop-semicolon-required**: A declaration with no terminating `;` (the last declaration of a block that omits it) MUST NOT be read.
- **prop-value-ends-at-semicolon**: A value MUST end at its first `;`, so a value that contains a semicolon (for example a `url(data:...;base64,...)`) is cut at that semicolon.
- **prop-ordered**: The `Map` MUST iterate in order of first appearance.
- **prop-duplicates**: When a name is declared twice, the later value MUST replace the earlier one, and the entry MUST keep the position of the first declaration.
- **prop-empty-value-kept**: A declaration whose value is only whitespace MUST still be read and stored as the empty string (the guard skips a match only when a capture is the empty string, and the value pattern cannot capture nothing).
- **non-custom-ignored**: Declarations that are not custom properties (names not starting with `--`) MUST be ignored.
- **comments-not-parsed**: The parser MUST NOT recognise CSS comments: a custom property written inside a comment within the block is read as if it were live.

### Ordering and concurrency

- **no-shared-state**: The shared module-level global regular expressions MUST NOT leak a match position between calls; `String.replace` and `matchAll` each start from the beginning of the string, so repeated and re-entrant calls give identical results.
- **synchronous**: Both functions MUST be synchronous and perform no I/O.

### Consumers

- **consumer-delta**: Consumer behaviour, recorded for orientation: the ADH theme style injector (its theme-switcher assets) parses the default theme's `:root` block, then for each switcher theme splits off the imports; a full-palette theme ships its remaining CSS whole with no delta, while any other theme ships a `:root` block of only the entries whose value differs from the base value. This module does not compute deltas.

