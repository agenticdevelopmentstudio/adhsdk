
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `entries` | `SiteEntry[]` | required | Full corpus of parsed site pages; input to `findBySlug`, `getBySection`, `getByDomain`, `buildNavTree`, and `createSearchIndex`. |
| `slug` | `string` | required | Path lookup key for `findBySlug` and `slugToBreadcrumbs`. |
| `section` | `string` | required | Exact-match filter key for `getBySection`. |
| `domain` | `string` | required | Exact-match filter key for `getByDomain`. |
| `sections` | `NavSectionConfig[]` | required | Declared nav sections (`key`, `label`, `path`) that seed `buildNavTree`'s top-level nodes and their order. |
| `index` | `SearchIndex` | required | The Fuse-backed index returned by `createSearchIndex`, injected into `useSearchState`. |
| Fuse `threshold` | `number` | `0.3` | Hardcoded fuzzy-match tolerance inside `createSearchIndex`; not exposed as a caller-supplied option. |
| Fuse `minMatchCharLength` | `number` | `2` | Hardcoded minimum characters before a match registers; not exposed as a caller-supplied option. |
| Fuse key weights | `number` | title `3`, summary `2`, domain `1` | Hardcoded relative weighting of the three indexed fields; not exposed as a caller-supplied option. |

