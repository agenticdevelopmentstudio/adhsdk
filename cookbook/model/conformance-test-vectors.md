
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
| site-model-018 | results-track-query, set-query-resets-selection | Call `setQuery('alph')` against entries `Alpha`, `Alphabet`, `Beta` | `results.length > 0` |
| site-model-019 | arrow-down-advances-selection | After `setQuery('alph')`, call `handleKey({key:'ArrowDown'})` | `selectedIndex === Math.min(1, results.length - 1)` |
| site-model-020 | arrow-up-retreats-selection | Continuing from site-model-019, call `handleKey({key:'ArrowUp'})` | `selectedIndex === 0` |
| site-model-021 | escape-resets | After `setQuery('alph')`, call `handleKey({key:'Escape'})` | `query === ''` and `results` equals `[]` |
| site-model-022 | unhandled-key-no-op | With `query` already `'alph'` and `results` non-empty, call `handleKey({key:'Enter'})` | `query`, `results`, and `selectedIndex` are unchanged from immediately before the call |
| site-model-023 | arrow-down-advances-selection | Call `handleKey({key:'ArrowDown'})` when `results.length === 0` | `selectedIndex` stays `0` |
| site-model-024 | selected-index-direct-set-unclamped | Call `setSelectedIndex(99)` when `results.length === 1` | `selectedIndex === 99` (not clamped) |

