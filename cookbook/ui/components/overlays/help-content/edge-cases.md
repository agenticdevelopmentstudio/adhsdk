
- **No provider mounted**: useHelpEntry called without a HelpContentProvider ancestor returns undefined; no error is thrown. The reason for not throwing is recorded in Design Decisions.
- **Inherited-key lookup**: useHelpEntry("constructor") or other inherited property names return undefined. See `#requirements/exclude-inherited-properties`; the lookup method is recorded in Design Decisions.
- **Empty help dictionary**: HelpContentProvider mounted with empty `help={{}}` causes useHelpEntry to return undefined for any id queried. See `#requirements/return-undefined-on-missing-id`.
- **Help data prop changes**: HelpContentProvider passes `help` straight through as the context value without memoizing it. If a caller supplies a new object reference on every render (for example, an inline object literal), context consumers re-render on every parent render even though the entries themselves did not change. Callers SHOULD hold `help` in a stable reference (a module-level constant, or a value the caller memoizes) to avoid those unnecessary re-renders; HelpContentProvider itself does not memoize the prop.

