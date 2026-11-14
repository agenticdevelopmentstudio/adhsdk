
| String Key | Default (en) | Context |
|-----------|---------------|---------|
| (hardcoded, not externalized) | "Copy" | Copy button default label |
| (hardcoded, not externalized) | "Copied" | Copy button label shown for 1200ms after a successful copy |

`"Copy"` and `"Copied"` are hardcoded string literals in `SourceCodePanel.tsx`; no prop or localization hook exists in source to translate them, so the component cannot currently be localized into another language without patching or wrapping it.

