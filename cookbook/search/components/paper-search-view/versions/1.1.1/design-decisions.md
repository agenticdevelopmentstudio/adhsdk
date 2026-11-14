
**Decision**: Paper Search View exists as a wrapper component that centralizes SearchSource configuration and prop defaults in one place, rather than letting each mount point (corpus-wide search page, author index page) configure its own SearchView.
**Rationale**: This prevents configuration drift between mounting contexts — without a single wrapper, "the author page searches something slightly different from /search" is a one-line drift away. This prioritizes consistency over flexibility: local customization goes through the explicit props interface rather than direct SearchView configuration at the call site.
**Approved**: pending

**Decision**: The accessible names (`searchLabel`, `searchPlaceholder`, `searchLandmarkLabel`) are props with string defaults, not literals baked into SearchView.
**Rationale**: The package owns the UI but the host owns the words. This lets the same component mount on multiple sites, or in multiple languages, without modification, delegating vocabulary choices to the host application.
**Approved**: pending

**Decision**: `documentHref` is required at every call site rather than derived from configuration.
**Rationale**: This implements the LINK seam documented in `packages/web/packages/search/src/types.ts` (one of the package's three configurable seams: SCOPE/SOURCE, DOCUMENT-TYPE, and LINK) — the URL space belongs to the host, not the search package, because the same corpus is addressed differently on different hosts and the component must not assume or prescribe the URL scheme.
**Approved**: pending

