
`slugToBreadcrumbs` (`lib/breadcrumbs.ts`) and `buildNavTree`'s
orphan-section path (`lib/nav.ts`) each carry an identical private
`titleCase` helper that derives a human-readable label directly from a URL
segment — splitting on `-`, uppercasing only each word's first character, and
joining with spaces — with no locale parameter, no resource-bundle lookup,
and no seam for a caller to supply a translated label. Every label this
module produces (breadcrumb labels, orphan nav-section labels) is therefore
hardcoded, English-oriented text derived mechanically from the URL segment,
not sourced from a string table.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| *(none — no string table)* | `titleCase(segment)`, e.g. `Getting Started` from `getting-started` | Breadcrumb label (`lib/breadcrumbs.ts`) and orphan nav-section label (`lib/nav.ts`) |

