
- **string-externalization**: NEEDS REVIEW: Not implemented in source. The strings the model returns ("Connected", "Error", "Reconnect needed", "Pending", "Never synced", "Last synced ", "Stored (hidden)", "Checking for an OAuth client…", the two OAuth client descriptions, and the incomplete-form error) are English literals with no localization lookup; evidence that would settle it is the product's localization decision for the Integrations settings screen.
- **relative-date-locale**: The model MUST format the relative date with the given locale, which defaults to the current locale; the surrounding "Last synced " prefix is not localized.

