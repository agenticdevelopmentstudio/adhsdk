
`ThemeStore` is the catalog of selectable themes. It concatenates the built-in themes (`BuiltInThemes.all`) with the user's custom themes, which it reads from and writes to an injected `ThemeStorage`. It also holds the mutators that create custom themes: add, update, delete, add-new, duplicate, and three import paths (`.itermcolors`, `ColorTheme` JSON, and a content-sniffing front door), plus `exportJSON`. The same file declares `ThemeImportError`, the user-facing errors the JSON import raises.

It is Foundation-only and `@MainActor`, with no AppKit and no settings system, so it ships on every platform and is tested against an in-memory storage. The store caches nothing: every read goes to storage. Palette parsing lives in `ITermColorsParser`, the theme value type in `ColorTheme`, and the active-theme selection in `ThemeManager`; this recipe covers only the catalog and its persistence calls.

