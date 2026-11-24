
The source contains three hardcoded English strings: the `[image omitted]` placeholder, the `Error: ` prefix on failed tool results, and the fallback stream error text `provider stream error`. They are not localized and not externalized; they are part of the wire text sent to a model or client, not interface text for people. Provider error messages pass through as the provider wrote them.

