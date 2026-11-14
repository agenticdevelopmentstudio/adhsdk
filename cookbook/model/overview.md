
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

