
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
  accumulated path. The accumulated path includes the section segment: for
  the slug `/guides/install/linux/x`, the `install` node's path is
  `/guides/install` and the `linux` node's path is `/guides/install/linux`.
  Known source behavior: because a leaf is never reused, a leaf followed by a
  same-label folder yields two sibling nodes with that label (site-model-027);
  a port is not required to treat that as a design goal.
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
- **search-result-order**: `SearchIndex.query` MUST return its pairs in the
  order Fuse.js returns them: ascending `score`, where `score` is Fuse's
  weighted match score between `0` (exact match) and `1` (no match), so a
  lower score is a better match and the best match comes first.

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
- **memoize-search-inputs**: Callers SHOULD memoize the `SearchIndex` passed
  into `useSearchState`, and the `entries` array passed to `createSearchIndex`
  and `buildNavTree`. `results-track-query`'s `useMemo` depends on the
  referential identity of `index`, so a newly constructed `SearchIndex` on
  every render rebuilds the underlying Fuse instance on every re-render. This
  is a caller-side performance recommendation, not a contract the sources
  enforce.
- **selected-index-direct-set-unclamped**: `setSelectedIndex` is the raw state
  setter, and `useSearchState` applies no clamp to it: a value past
  `results.length - 1` is stored as given. Known source behavior, pinned by
  site-model-024; a port may clamp out-of-range values without breaking any
  other requirement.

