
- **body field**: The `body` property is a plain string, not JSX or ReactNode. This is intentional: many consuming site configs are authored as `.ts` modules without JSX support and cannot express ReactNode values. Localization of help text is handled by the consuming application over its own per-locale help content file.
- **title field**: The optional `title` property is also a plain string for the same reason.
- **flavor field**: The `flavor` property is not localized; it is a semantic tag for the UI layer to interpret.

