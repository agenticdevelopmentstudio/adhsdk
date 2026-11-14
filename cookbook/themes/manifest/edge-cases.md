
- **Null and empty input**: The module takes no input. A lookup with an empty string, `undefined` or `null` yields `undefined` from the record; the consumer MUST handle it (`ThemeStyle` renders nothing for an unknown key).
- **Boundary values**: Display names include non-ASCII characters (middle dot, `é`) and an apostrophe; they MUST be preserved exactly. `themeIds` has a fixed length of 39.
- **Key and id drift**: An entry whose `id` differs from its record key compiles. This is a hand-maintenance risk the types do not catch; the only runtime check is the test for the two rescued themes. Consumers MUST NOT assume it is verified for every theme.
- **Missing registration**: A stylesheet in `theme-data` that nobody lists in the manifest is unreachable and invisible, per the comment in `rescued-themes.test.ts`. A key that is listed but whose export is missing fails at build time.
- **Concurrent access**: Not applicable: the module is evaluated once, holds constants and has no asynchronous operation. Nothing prevents a consumer from mutating `themes` or `themeIds`, since neither is frozen.
- **Error states and offline**: Not applicable: the module reads no file, network or storage at run time; the stylesheet text is bundled at build time through imports.
- **Large payload**: The manifest imports all 39 stylesheets as strings, so importing it loads every theme's text, even if only one is used. The source has no lazy loading.

