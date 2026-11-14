
### Types and exports

- **theme-style-props**: `ThemeStyle` MUST accept `theme` (a `ThemeKey`, required), `scope` (an optional string) and `colorMode` (an optional `ThemeColorMode`, default `system`).
- **theme-color-mode-type**: `ThemeColorMode` MUST be exactly one of `system`, `light` or `dark`.
- **build-scoped-css-signature**: `buildScopedCss(css, scope, colorMode)` MUST take a stylesheet string and a scope selector, take `colorMode` as an optional third argument defaulting to `system`, and return a string.
- **public-transform**: `buildScopedCss` MUST be exported from the `ThemeStyle` module; the source's test calls it a public export whose legacy `:root` forms must keep resolving even though no shipped theme uses them. The package index re-exports only `ThemeStyle` and `ThemeStyleProps`, and `package.json` has no `./ThemeStyle` subpath, so the function is reachable by deep path to the built `ThemeStyle` entry, not from the package root.

### Component rendering

- **unknown-theme-renders-nothing**: When `themes[theme]` has no entry, `ThemeStyle` MUST return `null` and MUST NOT throw; the source comment gives a stale persisted choice or a typo in a consumer's theme list as the cases.
- **unscoped-passthrough**: When `scope` is absent or an empty string, `ThemeStyle` MUST emit the theme's CSS unchanged, `@import` lines included.
- **scoped-transform**: When `scope` is a non-empty string, `ThemeStyle` MUST emit the result of `buildScopedCss(entry.css, scope, colorMode)`.
- **color-mode-scoped-only**: `colorMode` MUST have no effect when `scope` is not set.
- **inline-style-element**: `ThemeStyle` MUST render a single `style` element inline in the component's own output, not append it to `document.head` through an effect, so the CSS is in server-rendered HTML and applies on first paint.
- **raw-css-body**: The `style` element's body MUST be set as raw HTML (`dangerouslySetInnerHTML`) so CSS punctuation such as `>` is not escaped; the source comment notes the CSS comes from the static theme manifest, not user input.
- **rerender-swaps-css**: Re-rendering with a different `theme`, `scope` or `colorMode` MUST replace the style body with the newly resolved CSS.

### Element ids

- **global-id**: An unscoped `style` element MUST carry the id `adh-sdk-theme`.
- **scoped-id-prefix**: A scoped `style` element MUST carry an id of the form `adh-sdk-theme-scoped-<slug>` when `scope` is already its own slug, and `adh-sdk-theme-scoped-<slug>-<hash>` otherwise, where `<hash>` is the 32-bit FNV-1a hash of the raw `scope` string in base 36.
- **scoped-id-slug**: The slug MUST be built by replacing every run of characters outside `a-z`, `A-Z`, `0-9`, `_` and `-` with a single `-`, trimming leading and trailing `-`, then lowercasing.
- **distinct-scope-ids**: Two different `scope` strings MUST get different ids, even when they reduce to the same slug (for example `.host-a`, `#host-a`, `.Host-A` and `host-a`). The hash suffix on every scope that is not its own slug guarantees this.

### Scoped CSS output

- **scope-wrapper**: `buildScopedCss` MUST return the hoisted imports, a newline, `@scope (<scope>) {`, a newline, the rewritten body, a newline and `}`.
- **import-hoisting**: Every line of the form `@import url(...);` (the entire line, optional trailing whitespace) MUST be removed from the body and placed, joined by newlines, before the `@scope` block, because an `@import` is invalid inside a rule.
- **import-form-limit**: Only the `@import url(...)` form on its own line is hoisted; an `@import` written any other way stays in the body.
- **anchors-at-line-start**: Every root-anchor rewrite MUST match only at a line start, after optional spaces or tabs, or after a comma and optional whitespace, so an indented rule (such as one nested in a media block) is rewritten and prose or property values are not.
- **horizontal-whitespace-only**: The leading-whitespace allowance MUST be spaces and tabs only, never newlines, so a match cannot swallow a preceding blank line.
- **html-root-bare**: A bare `html:root` anchor (followed by whitespace, a comma or `{`) MUST become `:scope`.
- **html-root-qualified**: An `html:root` anchor followed by any run of attribute selectors or `:not(...)` qualifiers MUST be rewritten to `html<qualifiers> :scope`, moving the qualifiers onto an `html` ancestor of the scope, because they describe the document, not the scoped element.
- **html-root-light-anchor**: An `html:root[data-color-mode]:not(.dark)` anchor that is the entire selector of its own rule (immediately followed by optional whitespace and `{`) MUST be rewritten according to `colorMode`: `system` gives `html[data-color-mode]:not(.dark) :scope`, `light` gives `:scope`, `dark` gives `:scope.pc-colormode-off`.
- **light-anchor-not-in-lists**: The same discriminator MUST NOT receive the colorMode rewrite when it is followed by a comma or by further qualifiers (it is then not directly followed by `{`); it takes the qualified rewrite instead, so dark-always themes (charcoal, fishlamp), whose combined selector list ends in qualified members, get no light variant forced on them. The rule is a lookahead for `{`, not a check that the item stands alone: the same discriminator written as the last item of a comma list, directly before `{`, would still receive the colorMode rewrite.
- **legacy-root-dark**: A `:root.dark` anchor MUST become `:scope` for `dark`, `:scope.pc-colormode-off` for `light` and `html.dark :scope` for `system`.
- **legacy-root-not-dark**: A `:root:not(.dark)` anchor MUST become `:scope` for `light`, `:scope.pc-colormode-off` for `dark` and `html:not(.dark) :scope` for `system`.
- **legacy-root-bare**: A bare `:root` anchor (followed by whitespace, a comma, `{` or `:`) MUST become `:scope`.
- **body-anchor**: A `body` selector (followed by whitespace, a comma, `{`, `:` or `.`) MUST become `:scope`.
- **rewrite-order**: The rewrites MUST run in this order: import removal, `html:root` light anchor, `html:root` qualified, `html:root` bare, `:root.dark`, `:root:not(.dark)`, bare `:root`, `body`; qualified forms are tried before bare ones so a document qualifier is never left on the scoped element.
- **forced-mode-keeps-dark-block**: For `light`, the bare `html:root` dark block MUST NOT be removed; both blocks become `:scope` and the light block wins because it is later in source order. For `dark`, the light block is sent to the never-matching selector.
- **never-selector**: The never-matching selector MUST be `:scope.pc-colormode-off`.
- **system-mode-default**: With `colorMode` of `system`, the output MUST follow the document: dark rules apply under `html.dark` and light rules under `html:not(.dark)` or `html[data-color-mode]:not(.dark)`.
- **no-anchor-left-behind**: No shipped theme's scoped output MUST contain an unrewritten `:root` or `html:root` anchor at a line start or after a comma; the source test asserts this against every stylesheet in the manifest.
- **scope-not-escaped**: `buildScopedCss` MUST insert `scope` into the `@scope (...)` prelude as given, with no validation or escaping; an invalid selector yields CSS the browser ignores.

### Ordering and concurrency

Not applicable: `buildScopedCss` is a synchronous pure function, `ThemeStyle` renders synchronously on the single JavaScript thread with no effects, and neither keeps module state beyond compiled regular expressions and constants.

### Persistence, network and side effects

Not applicable: the module reads no storage, makes no network request and writes nothing but the rendered `style` element. The `@import` lines it hoists are fetched by the browser, not by this code.

