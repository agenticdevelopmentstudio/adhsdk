
### Lookup (`lib/lookup.ts`)

- **find-by-slug**: `findBySlug` MUST return the first entry in the given
  `SiteEntry[]` array whose `slug` field strictly equals the given slug, or
  `undefined` when no entry matches.
- **entries-by-section**: `getBySection` MUST return every entry whose
  `section` field strictly equals the given section, in the same relative
  order the entries appear in the input array.
- **entries-by-domain**: `getByDomain` MUST return every entry whose `domain`
  field strictly equals the given domain, in the same relative order the
  entries appear in the input array.

### Breadcrumbs (`lib/breadcrumbs.ts`)

- **root-slug-breadcrumbs**: `slugToBreadcrumbs` MUST return an empty array
  when given the slug `/`.
- **breadcrumb-per-segment**: For any other slug, `slugToBreadcrumbs` MUST
  return exactly one `BreadcrumbEntry` per non-empty path segment, in
  left-to-right order, with no synthetic "Home" entry prepended.
- **breadcrumb-path-accumulation**: Each breadcrumb's `path` MUST be the
  `/`-joined, leading-slash-prefixed accumulation of every segment up to and
  including that breadcrumb's own segment.
- **breadcrumb-label-title-case**: Each breadcrumb's `label` MUST be produced
  by splitting the segment on `-`, uppercasing only the first character of
  each resulting word, and joining the words with a single space, without
  otherwise altering the case of any character after that word's first.

### Nav tree (`lib/nav.ts`)

- **declared-sections-seed-tree**: `buildNavTree` MUST create one top-level
  `NavNode` for every entry in the given `sections` array, in the order the
  sections appear in that array, using the section's `label` and `path`
  verbatim and an empty `children` array, before any `entries` are
  processed.
- **entry-section-skip**: `buildNavTree` MUST skip any entry whose `section`
  field is falsy or whose `slug` is exactly `/`, adding no node for it
  anywhere in the tree.
- **orphan-section-creation**: When an entry's `section` does not match any
  key declared in `sections`, `buildNavTree` MUST create a new top-level node
  for that section, using `titleCase(entry.section)` as its label and
  `"/" + entry.section` as its path, appended after the sections already
  known at that point in the traversal.
- **section-index-domain**: When an entry's slug resolves to no path segments
  beyond the section (the slug is exactly `/<section>`), `buildNavTree` MUST
  set that section node's own `domain` field to the entry's `domain` and
  MUST NOT add a child node for that entry.
- **intermediate-segment-nodes**: For each intermediate path segment (every
  segment except the last) in an entry's slug, `buildNavTree` MUST reuse an
  existing child node of the current node when that child's label equals
  `titleCase(segment)` and the child already has at least one child of its
  own; otherwise it MUST create a new child node with that label and the
  accumulated path.
- **leaf-node-creation**: `buildNavTree` MUST append a leaf `NavNode` for the
  entry's final path segment, using `entry.frontmatter.title` as the label,
  `entry.slug` as the path, and `entry.domain` as the domain.
- **tree-sort-order**: `buildNavTree` MUST sort the children of every node,
  recursively, so that nodes with one or more children sort before nodes
  with none, and nodes on the same side of that split sort alphabetically by
  `label` using locale-aware comparison (`String.localeCompare`).
- **tree-return-shape**: `buildNavTree` MUST return the top-level nodes as an
  array in the order established by declared-sections-seed-tree and
  orphan-section-creation, filtered of any `undefined` entries, without
  independently alphabetizing that top-level array.

### Search index (`lib/search.ts`)

- **search-index-fields**: `createSearchIndex` MUST index each entry's
  `frontmatter.title` (weight 3), `frontmatter.summary` (weight 2), and
  `domain` (weight 1) fields using a fuzzy-match threshold of `0.3` and a
  minimum match character length of `2`.
- **empty-query-short-circuit**: `SearchIndex.query` MUST return an empty
  array, without performing a search, when the given query is empty or
  contains only whitespace.
- **search-result-shape**: For a non-blank query, `SearchIndex.query` MUST
  return an array of `{ entry, score }` pairs, one per match, where `score`
  is the underlying match score, or `0` when no score is provided.

### Search state hook (`hooks/useSearchState.ts`)

- **initial-search-state**: `useSearchState` MUST initialize `query` to the
  empty string and `selectedIndex` to `0`.
- **results-track-query**: `useSearchState` MUST recompute `results` by
  calling `index.query(query)` whenever `index` or `query` changes.
- **set-query-resets-selection**: `setQuery` MUST update `query` to the given
  value and MUST reset `selectedIndex` to `0` in the same call, regardless of
  whether the new value differs from the current query.
- **reset-clears-state**: `reset` MUST set `query` to the empty string and
  `selectedIndex` to `0`.
- **arrow-down-advances-selection**: On an `ArrowDown` key, `handleKey` MUST
  advance `selectedIndex` by one, clamped to no more than
  `results.length - 1` (or `0` when `results` is empty).
- **arrow-up-retreats-selection**: On an `ArrowUp` key, `handleKey` MUST
  decrease `selectedIndex` by one, clamped to no less than `0`.
- **escape-resets**: On an `Escape` key, `handleKey` MUST perform the same
  clearing behavior as `reset`.
- **unhandled-key-no-op**: For any key other than `ArrowDown`, `ArrowUp`, or
  `Escape`, `handleKey` MUST leave `query`, `results`, and `selectedIndex`
  unchanged.
- **selected-index-direct-set-unclamped**: `setSelectedIndex` MAY be called
  directly by the caller to set `selectedIndex` to any value; `useSearchState`
  MUST NOT clamp that value against `results.length`.

