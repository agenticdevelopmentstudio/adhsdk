
- **Empty sections array**: When nav.sections is empty, sectionLabels MUST be an empty object; SearchDialog receives valid (empty) sectionLabels and renders without error.
- **Zero-entry searchIndex**: `useContent()` types `searchIndex` as a required, non-optional `SearchIndex`, always constructed by `ContentProvider` via `createSearchIndex(entries)` — this component never receives a null or undefined index, so it performs no defensive check of its own. An index built from zero entries still renders normally: `index.query()` returns an empty results array and SearchDialog shows no results rather than crashing.
- **Missing entry.slug on selection**: `SiteEntry.slug` is typed as a required `string`, and SearchDialog only ever calls `onSelect` with an entry drawn from `state.results`, whose entries come from that same typed `SiteEntry[]`. `entry.slug` is therefore guaranteed by the type system; this case cannot occur.

