
The component's only default strings — the `"Filter"` accessible-name label and
the `"Filter…"` placeholder — are hard-coded, user-visible English in the source
(`blocks/list-header.tsx`); they are not externalized into a localization
resource file. Consumers that need a localized experience MUST supply
`search.label` and `search.placeholder` with locale-appropriate strings (or
localize the two defaults upstream) — the component does not localize them on
its own.

