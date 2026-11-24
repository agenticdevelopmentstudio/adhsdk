
- **empty-entries-lookup** (null/empty input): `findBySlug` MUST return
  `undefined`; `getBySection` and `getByDomain` MUST return `[]`. This is the
  native behavior of `Array.prototype.find`/`.filter` on an empty array
  (`lib/lookup.ts`).
- **empty-slug-breadcrumbs** (boundary value): `slugToBreadcrumbs`
  MUST return `[]`, because `''.split('/').filter(Boolean)` yields no
  segments — the same effective result as the explicit `/` case, though only
  `/` is checked directly (`lib/breadcrumbs.ts`).
- **separator-runs-in-slug** (e.g. `/guides//x/`)
  (boundary value): `slugToBreadcrumbs` MUST produce breadcrumbs only for the
  non-empty segments, since `.filter(Boolean)` drops the empty strings that
  consecutive or trailing `/` characters produce.
- **empty-entries-nav-tree** (null/empty input):
  MUST still return one node per declared section, each with `children: []`
  (test-verified in `nav.test.ts`).
- **falsy-entry-section** (null/empty
  input): `buildNavTree` MUST skip the entry entirely, producing no node for
  it anywhere in the tree.
- **duplicate-section-keys**: NEEDS REVIEW: Not implemented in source. Duplicate keys within the `sections` array passed to `buildNavTree` (boundary/malformed input): `sectionMap.set` overwrites the earlier node for a repeated key, but `sectionOrder` still records the key twice, so the array returned by `buildNavTree` (`sectionOrder.map((key) => sectionMap.get(key)!)`) contains the same node object twice; the source never validates that section keys are unique, and there is no rule for which duplicate should "win" — a fix needs either a uniqueness check before calling `buildNavTree` or a decision on de-duplication.
- **missing-leaf-title** (malformed input): `SiteFrontmatter.title` is typed as a required `string`, so `buildNavTree` reads `entry.frontmatter.title` directly into the leaf node's `label` with no runtime fallback or validation, relying entirely on that type contract from a well-typed caller; `tree-sort-order`'s subsequent `a.label.localeCompare(b.label)` would throw a `TypeError` only if a caller violated that contract by supplying a missing or non-string title.
- **empty-entries-search-index** (null/empty
  input): MUST build a valid, empty Fuse index; `query` MUST return `[]` for
  any input against it (site-model-028).
- **whitespace-only-query** (e.g. `'   '`)
  (boundary value): MUST return `[]` per the `q.trim()` guard, without
  invoking Fuse's search (site-model-029).
- **arrow-down-without-results** (boundary value):
  MUST leave `selectedIndex` at `0`, because
  `Math.max(results.length - 1, 0)` evaluates to `0` and
  `Math.min(i + 1, 0)` cannot exceed it.
- **shared-index-queries** (concurrent access): Concurrent calls to
  `SearchIndex.query` from callers sharing one `SearchIndex` MUST be safe (no test asserts this). `query` performs a
  read-only `fuse.search` call against a Fuse instance that is never mutated
  after `createSearchIndex` constructs it, and JavaScript's single-threaded
  execution model serializes all such calls regardless of caller count.
- **unmount-during-use** (cancellation): Unmounting or cancelling while
  `useSearchState` is in use MUST simply stop invoking the hook's callbacks; there is no in-flight
  asynchronous work to cancel, because `index.query` and every state update
  in `useSearchState.ts` are synchronous (no test asserts this).
- **dependency-unavailable** (error states/offline):
  Not applicable — none of the five sources performs a network request, file
  read, or any other external call; `createSearchIndex` and its consumers
  operate entirely on the in-memory `SiteEntry[]` array the caller supplies.

