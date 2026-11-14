
- **Empty plugin or field text**: An empty component encodes to the empty string, so `fieldKey(plugin: "", field: "k")` is `aiplugin..field.k`. The component performs no emptiness check; callers own it. MUST.
- **Delimiter-like text**: A plugin or field containing `.`, `field` or `secretfields` MUST NOT alias another pair's key, because dots are escaped. MUST.
- **Percent sign in a component**: A literal `%` is escaped as `%25`, so an already-encoded input is encoded again and never aliases its decoded form. MUST.
- **Non-ASCII letters**: The allowed set is the platform's alphanumerics, which includes Unicode letters and digits, so those pass through unescaped. A port MUST match the same character set or the keys will differ. MUST.
- **Encoding failure fallback**: If the platform encoder returns nil the raw text is used, which would reintroduce delimiter ambiguity for that component. The source gives no case where this happens for a Swift `String`. MUST (stated as the actual behavior).
- **Ledger value format**: The ledger value is newline-joined field keys; a field key that contains a newline would be split into two entries when read back with a newline split, and empty entries are dropped on read in `PreferencesService`. MUST (stated as observed behavior of the caller).
- **Concurrent access**: Not applicable — every member is a pure function with no shared state.
- **Error states and offline state**: Not applicable — the component performs no I/O and has no dependency that can fail or disconnect.
- **Boundary length**: No length limit is applied; very long components produce very long keys, and limits of the settings table or Keychain are outside this component. MUST.

