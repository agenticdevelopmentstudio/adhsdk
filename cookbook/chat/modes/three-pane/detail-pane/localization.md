
The pane is not localized. It renders two hardcoded English strings and contains no localization layer: neither string is read from a key, a message catalog, or a translation hook, and no fallback or locale-selection logic exists. The keys below are names a consuming application would have to introduce; they do not exist today. See **literal-ui-strings**.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none — hardcoded | "Details" | Header text of the detail pane, written as a literal in the component markup |
| none — hardcoded | "Links" | Section label rendered above the links list, written as a literal in the component markup |

Link labels and image alt text are not UI strings: they arrive through the `topic` prop and are rendered verbatim, so localizing them is the caller's responsibility.

