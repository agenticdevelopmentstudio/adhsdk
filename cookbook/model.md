---
id: 120ac7e5-949e-40c9-bb15-b24350356763
title: "Site Model"
type: ingredient
version: 1.0.3
status: review
language: en
created: 2026-09-23
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "In-memory site content model: slug lookup, breadcrumb generation, nav-tree building, fuzzy search indexing, and a headless React search-state hook."
platforms:
  - typescript
  - web
tags:
  - site
  - search
  - navigation
  - content
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Site Model

## Overview

`site-model` is the in-memory content model behind a documentation/marketing
site. Given the parsed page corpus (`SiteEntry[]`) and the declared nav
configuration (`NavSectionConfig[]`), it answers four questions: which entry
lives at a given slug (`lookup.ts`), what breadcrumb trail leads to a slug
(`breadcrumbs.ts`), what the section/page tree looks like (`nav.ts`), and
which entries fuzzy-match a search query (`search.ts`) — plus a headless
React hook (`useSearchState.ts`) that wires a `SearchIndex` to
keyboard-driven selection state for a search palette. Inputs: `entries` is the full `SiteEntry[]` corpus (for `findBySlug`, `getBySection`, `getByDomain`, `buildNavTree`, `createSearchIndex`); `slug`, `section` and `domain` are the exact-match keys for lookup and breadcrumbs; `sections` is the declared `NavSectionConfig[]` (`key`, `label`, `path`) that seeds `buildNavTree`; `index` is the `SearchIndex` that `createSearchIndex` returns and `useSearchState` takes. None of the five
sources performs network, file-system, or persistence access; every function
is a synchronous, pure transformation over caller-supplied arrays, and the
hook holds only transient React state.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a data/search/navigation model, not a visual
component.

## States

Not applicable — this is a data/search/navigation model, not a visual
component.

## Accessibility

Not applicable — this is a data/search/navigation model, not a visual
component.

## Conformance Test Vectors

Traced to `hooks/__tests__/useSearchState.test.ts`,
`lib/__tests__/lookup.test.ts`, `lib/__tests__/breadcrumbs.test.ts`,
`lib/__tests__/nav.test.ts`, `lib/__tests__/search.test.ts`, and direct
inspection of the five sources where no test asserts the behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| site-model-001 | find-by-slug | `findBySlug(entries, '/g/b')` where `entries` contains slugs `/g/a`, `/g/b`, `/h/c` | Returns the entry whose `slug` is `/g/b` (`frontmatter.title` `'B'`) |
| site-model-002 | find-by-slug | `findBySlug(entries, '/nope')` against the same `entries` | Returns `undefined` |
| site-model-003 | entries-by-section | `getBySection(entries, 'g')` where entries `/g/a`, `/g/b` precede `/h/c` | Returns `['/g/a', '/g/b']` in that order |
| site-model-004 | entries-by-domain | `getByDomain(entries, 'd2')` where only `/h/c` has `domain: 'd2'` | Returns `['/h/c']` |
| site-model-005 | root-slug-breadcrumbs | `slugToBreadcrumbs('/')` | Returns `[]` |
| site-model-006 | breadcrumb-per-segment, breadcrumb-path-accumulation | `slugToBreadcrumbs('/guides/install')` | Returns `[{label:'Guides',path:'/guides'},{label:'Install',path:'/guides/install'}]` |
| site-model-007 | breadcrumb-label-title-case | `slugToBreadcrumbs('/api/getting-started')[1]` | Returns `{label:'Getting Started', path:'/api/getting-started'}` |
| site-model-008 | declared-sections-seed-tree, tree-return-shape | `buildNavTree([], [{key:'guides',label:'Guides',path:'/guides'},{key:'api',label:'API',path:'/api'}])` | Returns 2 top-level nodes, `Guides` then `API`, each with `children: []` |
| site-model-009 | entry-section-skip | `buildNavTree` on entries that include `{slug:'/', section:'guides', frontmatter:{title:'Home'}}` plus the normal `guides`/`api` entries | No node anywhere in the tree has `path: '/'` |
| site-model-010 | orphan-section-creation | `buildNavTree` on entries including `{slug:'/misc/extra', section:'misc', frontmatter:{title:'Extra'}}` with `sections` declaring only `guides`/`api` | Tree contains a node with `path: '/misc'` whose one child has `label: 'Extra'` |
| site-model-011 | section-index-domain | An entry `{slug:'/guides', section:'guides', domain:'d-index'}` with `sections` declaring `guides` | The `guides` top-level node's `domain` becomes `'d-index'`; no child node is added for that entry |
| site-model-012 | intermediate-segment-nodes, leaf-node-creation, tree-sort-order | `buildNavTree` on `/guides/install` (`title:'Install'`) and `/guides/configure` (`title:'Configure'`) with `sections` declaring `guides` | `guides` node has 2 children labeled `Configure` and `Install`, alphabetically ordered |
| site-model-013 | tree-sort-order, tree-return-shape | `buildNavTree` on the entries above plus `/api/overview` with `sections` declaring `guides` then `api` | Top-level order is `Guides`, `API` (declared order, not alphabetical, since `API` < `Guides` alphabetically) |
| site-model-014 | search-index-fields, search-result-shape | `createSearchIndex(entries).query('install')` where one entry's `frontmatter.title` is `'Install Guide'` | Results include the entry with `slug: '/g/install'` |
| site-model-015 | search-index-fields | `createSearchIndex(entries).query('auth flows')` where only `/api/auth`'s `frontmatter.summary` is `'API auth flows'` | First result's `entry.slug` is `'/api/auth'` |
| site-model-016 | empty-query-short-circuit | `createSearchIndex(entries).query('')` | Returns `[]` |
| site-model-017 | initial-search-state | `renderHook(() => useSearchState(idx))`, no interaction | `query === ''`, `results` equals `[]`, `selectedIndex === 0` |
| site-model-018 | results-track-query, set-query-resets-selection | Call `setSelectedIndex(1)`, then `setQuery('alph')`, against entries `Alpha`, `Alphabet`, `Beta` | `results.length > 0` and `selectedIndex === 0` |
| site-model-019 | arrow-down-advances-selection | After `setQuery('alph')`, call `handleKey({key:'ArrowDown'})` | `selectedIndex === Math.min(1, results.length - 1)` |
| site-model-020 | arrow-up-retreats-selection | Continuing from site-model-019, call `handleKey({key:'ArrowUp'})` | `selectedIndex === 0` |
| site-model-021 | escape-resets | After `setQuery('alph')`, call `handleKey({key:'Escape'})` | `query === ''`, `results` equals `[]` and `selectedIndex === 0` |
| site-model-022 | unhandled-key-no-op | With `query` already `'alph'` and `results` non-empty, call `handleKey({key:'Enter'})` | `query`, `results`, and `selectedIndex` are unchanged from immediately before the call |
| site-model-023 | arrow-down-advances-selection | Call `handleKey({key:'ArrowDown'})` when `results.length === 0` | `selectedIndex` stays `0` |
| site-model-024 | selected-index-direct-set-unclamped | Call `setSelectedIndex(99)` when `results.length === 1` | `selectedIndex === 99` (not clamped) |
| site-model-025 | reset-clears-state | After `setQuery('alph')` and `setSelectedIndex(1)`, call `reset()` | `query === ''`, `results` equals `[]`, `selectedIndex === 0` |
| site-model-026 | empty-query-short-circuit | `createSearchIndex(entries).query('   ')` | Returns `[]` |
| site-model-027 | intermediate-segment-nodes | `buildNavTree` on `{slug:'/guides/install', section:'guides', frontmatter:{title:'Install'}}` then `{slug:'/guides/install/linux', section:'guides', frontmatter:{title:'Linux'}}`, with `sections` declaring `guides` | `guides` has two children labeled `Install`: a folder (path `/guides/install`, one child `Linux`) sorted first, and the leaf (path `/guides/install`, no children); the leaf is not merged into the folder |
| site-model-028 | empty-entries-search-index | `createSearchIndex([]).query('anything')` | Returns `[]` and does not throw |
| site-model-029 | whitespace-only-query | `createSearchIndex(entries).query('\t  ')` | Returns `[]` |
| site-model-030 | search-result-order | `createSearchIndex(entries).query('alph')` against entries `Alpha`, `Alphabet`, `Beta` | Every result's `score` is at least the previous result's `score`, and `Alpha` precedes `Beta` if `Beta` appears |
| site-model-031 | breadcrumb-path-accumulation, intermediate-segment-nodes | `buildNavTree` on `{slug:'/guides/install/linux/x', section:'guides', frontmatter:{title:'X'}}` with `sections` declaring `guides` | The `install` node has path `/guides/install`; its child `linux` has path `/guides/install/linux`; the leaf `X` has path `/guides/install/linux/x` |

## Edge Cases

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

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Fuse `threshold` | `number` | `0.3` | Hardcoded fuzzy-match tolerance inside `createSearchIndex`; not exposed as a caller-supplied option. |
| Fuse `minMatchCharLength` | `number` | `2` | Hardcoded minimum characters before a match registers; not exposed as a caller-supplied option. |
| Fuse key weights | `number` | title `3`, summary `2`, domain `1` | Hardcoded relative weighting of the three indexed fields; not exposed as a caller-supplied option. |

The functions' inputs (`entries`, `slug`, `section`, `domain`, `sections`, `index`) are call parameters, not configuration; they are described in the Overview and in Behavioral Requirements.
## Deep Linking

Not applicable: none of the five sources registers or parses an app-scheme or
universal-link URL; `slugToBreadcrumbs` and `buildNavTree` only produce path
strings (`path`, `slug`) for an in-app web router.

## Localization

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

## Accessibility Options

Not applicable — this is a data/search/navigation model, not a visual
component; it has no motion, contrast, or color affordance for Reduce
Motion, Increase Contrast, or Differentiate Without Color to act on.

## Feature Flags

Not applicable: none of the five sources reads a flag, config toggle, or
environment switch before executing; every function and hook runs
unconditionally.

## Analytics

Not applicable: none of the five sources calls an analytics, telemetry, or
event-tracking API.

## Privacy

Not applicable: the sources hold no credentials or tokens; the only
user-supplied value is the transient, in-memory search `query` string held by
`useSearchState`, which is never persisted to storage or transmitted over a
network by any of these five files.

## Logging

Not applicable: none of the five sources calls `console.*` or any logging
API.

## Platform Notes

- **SwiftUI**: model `useSearchState`'s `query`/`selectedIndex` pair as
  `@Published` properties on an `ObservableObject` (or `@Observable` under
  Swift 6), recompute `results` in a `didSet`/computed property the way
  `useMemo` does, and drive `handleKey` from `.onKeyPress` (or
  `NSEvent.keyDown` on macOS) with the same `ArrowDown`/`ArrowUp`/`Escape`
  branching. `findBySlug`/`getBySection`/`getByDomain` map directly to
  `Array.first(where:)`/`.filter`; there is no first-party fuzzy-match
  equivalent to Fuse.js, so a port needs a Swift package (or a hand-rolled
  weighted scorer) that can reproduce the same threshold/weight semantics.
- **Compose**: hold `query` and `selectedIndex` in `mutableStateOf` (or a
  `StateFlow` in a `ViewModel`), and derive `results` with `derivedStateOf`
  keyed on `index`/`query`, mirroring `results-track-query`. Kotlin's
  `List.firstOrNull { }`/`.filter` cover the lookup functions directly. As on
  Apple platforms, Kotlin has no built-in fuzzy-match library matching
  Fuse.js's weighted, threshold-based scoring, so a port needs an equivalent
  third-party library or a custom scorer.
- **React/Web**: this is the source platform. The five files are
  `hooks/useSearchState.ts`, `lib/breadcrumbs.ts`, `lib/lookup.ts`,
  `lib/nav.ts`, and `lib/search.ts` in
  `packages/web/packages/model/src`, and the `fuse.js`
  dependency is declared in `packages/web/packages/model/package.json`.
  `useSearchState` uses `useMemo`/`useState`/`useCallback`, and its in-repo
  consumer is `SearchDialogConnected.tsx` in `packages/web/packages/controls/src/search-dialog`.
- **AppKit / UIKit**: the lookup and breadcrumb functions translate directly
  to `NSArray`/`Array` predicate or block-based filtering; there is no
  React-style hook, so `useSearchState`'s state becomes a delegate/closure
  pair or a small controller object exposing the same `query`, `results`,
  `selectedIndex`, and key-handling methods, wired to `NSResponder`
  `keyDown(with:)` or `UIKeyCommand`. Note Foundation's
  `String.capitalized`/`localizedCapitalized` lowercase the remainder of each
  word and are locale-aware, unlike the source's `titleCase`, which only
  uppercases the first character and leaves the rest of each word's casing
  untouched — a literal port must replicate the source's naive behavior, not
  Foundation's, to stay conformant.
- **WinUI 3**: Expose
  `Query`, `Results`, and `SelectedIndex` as `INotifyPropertyChanged`
  properties on a view-model (or bind through `x:Bind` with
  `ObservableCollection<NavNode>` for the tree), replacing React's
  `useState`/`useMemo` with property setters that raise
  `PropertyChanged` and recompute `Results` inline. `findBySlug`,
  `getBySection`, and `getByDomain` map to LINQ's
  `.FirstOrDefault(predicate)` and `.Where(predicate).ToList()` over an
  `IEnumerable<SiteEntry>`. .NET's `System.Globalization.CultureInfo` /
  `TextInfo.ToTitleCase` is not a drop-in replacement for the source's
  `titleCase`: `ToTitleCase` lowercases the remainder of each word and
  applies locale rules, while the source only uppercases the first character
  of each `-`-split word and leaves the rest untouched — a conformant port
  must reimplement the source's exact character transform, not call
  `ToTitleCase`. There is no built-in fuzzy-match API in the .NET/Windows App
  SDK equivalent to Fuse.js's weighted, threshold-based scoring; a port needs
  either a NuGet package such as FuzzySharp (a different, Levenshtein-based
  algorithm, so scores and thresholds will not match numerically) or a
  hand-rolled scorer that reproduces Fuse.js's weighting (title `3`, summary
  `2`, domain `1`) and `0.3` threshold. Route `Escape`/`ArrowUp`/`ArrowDown`
  through `KeyDown`/`PreviewKeyDown` on the search `TextBox` or its hosting
  `AutoSuggestBox`, mapping to the same three branches as `handleKey`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/model/src/` | confirmed (1.0.3) |

## Design Decisions

**Decision**: Document `breadcrumbs.ts`'s and `nav.ts`'s private `titleCase`
helper once, as a single title-casing contract, rather than as two separate
requirements.
**Rationale**: The two functions are byte-for-byte identical (split on `-`,
uppercase only each word's first character, join with a space); treating
them as one shared behavior avoids stating conflicting requirements for what
is, in the source, unshared duplicated code — a maintenance liability worth
noting even though this ingredient does not change it.
**Approved**: pending

**Decision**: Preserve `intermediate-segment-nodes`'s exact reuse condition
(an existing child is only reused when it already has at least one child of
its own) rather than describing a simpler "reuse by label" rule.
**Rationale**: A leaf node that happens to share a label with a later
folder-shaped segment is not merged into it — the source creates a sibling
duplicate instead. This is the code's actual, traceable behavior, and
smoothing it into an idealized merge rule would violate source fidelity.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Both statuses rest on the Localization section above: `titleCase` in
`lib/breadcrumbs.ts` and `lib/nav.ts` builds every label this module emits
directly from a URL segment, in English, with no string-table lookup or
externalization seam of any kind. `separation-of-concerns` passes because every
source file (`useSearchState.ts`, `breadcrumbs.ts`, `lookup.ts`, `nav.ts`,
`search.ts`) is pure logic with no rendering of its own, and `unit-test-coverage`
passes because each file has a matching direct test (`useSearchState.test.ts`,
`breadcrumbs.test.ts`, `lookup.test.ts`, `nav.test.ts`, `search.test.ts`) with
meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation from web sources: `hooks/useSearchState.ts`, `lib/breadcrumbs.ts`, `lib/lookup.ts`, `lib/nav.ts`, `lib/search.ts`. |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.0.3 | 2026-11-14 | Mike Fullerton | Pinned search ordering, path format, memoize and unclamped behavior as requirements, named edge cases, fixed vectors and added seven, and moved inputs out of Configuration. |
