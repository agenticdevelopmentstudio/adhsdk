
- **Unknown theme key** (MUST): `ThemeStyle` renders nothing and does not throw, so a stale persisted choice does not take the page down.
- **Empty scope string** (MUST): treated as no scope; the CSS is emitted unscoped under `adh-sdk-theme`.
- **Empty stylesheet** (MUST): `buildScopedCss('', '.host')` returns an empty import line, then an `@scope (.host)` block with an empty body.
- **No imports** (MUST): the hoisted-imports part is an empty string, so the output begins with a newline.
- **Stylesheet with no recognised anchor** (MUST): rules pass through unchanged inside the `@scope` block; the module does not warn, which is how a new anchor shape would silently drop a palette (the reason the shipped-theme test exists).
- **Dark-always themes** (MUST): a theme whose light discriminator is followed by a comma or carries further qualifiers (charcoal's combined selector list) gets no light variant forced under `light`; its output is identical in all three modes.
- **Forced light keeps the dark block** (MUST): under `light` the dark `html:root` block still applies as `:scope`; the light block only wins by coming later in the stylesheet, so a theme with its light block first would render dark.
- **Selector that reduces to an empty or shared slug** (SHOULD NOT occur): a scope of only punctuation yields an empty slug and the id `adh-sdk-theme-scoped--<hash>`. Distinct selectors that share a slug still get distinct ids through the hash suffix (`distinct-scope-ids`).
- **Invalid scope selector** (not validated): the string is inserted as given and the browser discards the invalid `@scope` rule, so the theme silently does not apply.
- **Browser without `@scope` support** (not handled): the source has no fallback, so an engine that lacks `@scope` ignores the whole scoped block.
- **Unscoped colorMode** (MUST): `colorMode` is ignored without `scope`.
- **Multiple scoped themes on one page** (MUST): each scope gets its own id, so several blocks coexist; this is the case the id scheme exists for.
- **Server rendering** (MUST): the `style` element is part of the server HTML; nothing depends on `window` or `document`.
- **Network and offline**: not applicable; the module makes no requests (hoisted `@import` lines are the browser's concern).
- **Concurrent access**: not applicable; synchronous and stateless.

