
None: every component here renders data the host already holds in memory
(`nodes`, `crumbs`, `fields`, `html`, `source`) and makes no network request and
persists nothing. `DocArticle` renders host-supplied `html` via
`dangerouslySetInnerHTML`, which is a trust boundary documented in Configuration
above, not a data-collection concern.

