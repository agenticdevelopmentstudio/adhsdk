
The `closeLabel` prop's value, when supplied by the caller, should be localized by the caller — ContentOverlay performs no translation itself. The default value used when `closeLabel` is omitted, `'← back'`, is a hardcoded English string with a decorative arrow glyph baked into the same text node; it is not sourced from a localization resource and does not adapt to locale. Callers targeting non-English locales MUST always pass a localized `closeLabel` rather than relying on the default. See **default-close-label**.

