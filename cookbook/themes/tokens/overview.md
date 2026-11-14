
`tokens.ts` is the one parser for generated theme CSS. It is framework-free and isomorphic: it uses no DOM and no React, so the server-side theme style injector and the client theme editor share one implementation and cannot drift. It exports two pure functions and one type:

- `splitImports(css)` removes every `@import url(...)` rule from a theme's CSS and returns the removed hrefs beside the remaining CSS.
- `parseRootProps(css)` reads the first `:root { ... }` block of a generated theme and returns its custom properties as an insertion-ordered `Map` of name to value.
- `ThemeDelta` is the type of a theme's token map transferred as a delta: a record of custom-property name to value.

The header comment records that the token-classification, grouping and serialisation helpers that once lived in this file were dropped when the editor moved to free-form CSS, so the module is parsing only. The parser is regular-expression based; it is not a CSS parser, and the contract below describes exactly what those expressions accept. The themes package exposes the module as its `./tokens` export, and the ADH package imports it as `@adh-sdk/themes/tokens`: `AdhThemeStyle` calls both functions, and `themes-client` uses `ThemeDelta` for the stored theme `data` field and the theme write payload.

