
All labels, placeholders, and messages (`placeholder`, `triggerPlaceholder`, `okLabel`, `cancelLabel`, `createLabel`, `emptyLabel`, `ariaLabel`, `inputLabel`) are accepted as props, so the parent can supply localized strings for any language. Each prop's default value (`"Filter or add…"`, `"Select…"`, `"OK"`, `"Cancel"`, `` `Add “${text}”` ``, `"No matches"`) is English text baked into the component signature — a caller targeting another locale MUST override every default it uses rather than rely on it.

Filtering and exact-match resolution lowercase both the query and item labels (`.toLowerCase()`) for case-insensitive comparison. Casing is a locale-sensitive transform (e.g. Turkish dotless-ı), so this comparison may not behave as expected for every locale. Callers with locale-specific casing needs should pre-normalize `items` labels rather than relying on JavaScript's default, locale-unaware `toLowerCase()`.

