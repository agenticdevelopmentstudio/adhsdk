
Theme Fonts is the one export of `fonts.ts` in the themes package: `THEME_FONT_PRELOADS`, a read-only list of absolute, same-origin hrefs for the self-hosted Iosevka faces the adh theme ships. A page renders a `<link rel=preload>` for each so the browser starts the download while it is still parsing `<head>`, before any layout.

The module exists for the one thing CSS cannot express, telling the browser to fetch a font before layout. The `@font-face` rules themselves are emitted into the theme css by `scripts/build-tokens.mjs`. Both sides read the same manifest, `src/fonts/metrics.json`, written by `scripts/subset-fonts.py`, so a preload cannot point somewhere the css does not or name a file that no longer exists.

The source's doc comment says the list is consumed by a `ThemeStyle` component rendered in the `<head>` of every consuming site; in this repo the consumer is `AdhThemeStyle` in the adh package, which calls react-dom's `preload(href, { as: 'font', type: 'font/woff2', crossOrigin: 'anonymous' })` for each entry, and only when `usesBaseThemeFonts(DEFAULT_SITE_THEME)` is true, and that the bytes are placed at these paths by `materializeThemeFonts` (the package's `materialize-fonts.mjs`). The module is also published as the `./fonts` subpath export of the package.

