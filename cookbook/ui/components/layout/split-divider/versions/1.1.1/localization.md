
The component accepts all user-facing strings via props (`label`, `growBottomLabel`, `growTopLabel`), leaving localization entirely to the caller. The defaults it falls back to when a prop is omitted ("Resize split", "Grow top/bottom pane", "Grow left/right pane") are hardcoded English fallback strings. Callers SHOULD pass localized strings for every label rather than relying on these defaults.

