
The `label` and `noun` props are host-supplied and already localizable. The remaining microcopy is hardcoded English in the source and is not currently exposed as overridable props or externalized string keys:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `category-field.browse-trigger` | "Choose…" | EntityChooser trigger button label |
| `category-field.combobox-placeholder` | "Type a {noun}…" | Combobox placeholder |
| `category-field.browser-input-label` | "Filter or add a {noun}" | EntityChooser input label |
| `category-field.browser-input-placeholder` | "Filter or add a {noun}…" | EntityChooser input placeholder |
| `category-field.rename-button-label` | "Rename {noun} {name}" | Breadcrumb rename button `aria-label` |
| `category-field.browser-aria-label` | "Browse {label}" | EntityChooser `ariaLabel` |
| `category-field.path-singular` | "{label} path" | Breadcrumb `<nav>` `aria-label`, one trail |
| `category-field.path-plural` | "{label} paths" | Breadcrumb `<nav>` `aria-label`, multiple trails — a binary singular/plural, not a locale-aware plural rule (see Compliance: `plural-forms`) |

`label.toLowerCase()`, used to build the EntityChooser's `ariaLabel`, is a locale-sensitive casing transform, but the web source calls plain `toLowerCase()`, which is not locale-aware. This is a known gap, recorded under `string-externalization` in Compliance; ports SHOULD lowercase in the user's locale, since casing rules differ by language (e.g. Turkish dotless/dotted I).

