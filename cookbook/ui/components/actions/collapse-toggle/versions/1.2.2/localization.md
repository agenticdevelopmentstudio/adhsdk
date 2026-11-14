
The verbs "Expand" and "Collapse" are hard-coded English string literals inside the component. The source contains no string table, no message catalogue, no locale parameter, and no lookup call — the two words are written directly into the template literal that builds `aria-label` and `title`.

Everything else in the accessible name comes from the caller: `label` is interpolated verbatim, so the caller is the party that supplies a localized region name. A caller passing a localized `label` into this component gets a mixed-language accessible name (for example "Expand Themenliste") until the consuming application localizes the two verbs as well. Implementations that need a fully localized name MUST source the verbs from their own catalogue rather than from this component.

The glyphs `»` and `«` are literal characters in the JSX and are not mirrored, re-selected, or swapped for right-to-left locales.

