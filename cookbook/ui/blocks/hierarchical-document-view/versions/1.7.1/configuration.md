
| Component | Prop | Default | Meaning |
|---|---|---|---|
| `HierarchicalDocumentView` | `nav` | none | the nav column, normally a `DocNav`; rendered unwrapped, omit for a single-column reader |
| | `children` | — | the routed document region: one `DocPage` per route |
| `DocPage` | `toc` | none | the right rail, normally a `DocTableOfContents`; rendered unwrapped, omit to give the document the full width |
| | `children` | — | the document: breadcrumbs, article, metadata, source |
| `DocNavTree` | `nodes` | — | top-level sections in display order; each `{ label, href, headings?, children? }` |
| | `activePath` | — | the current route, spelled exactly as it appears in a node's `href` |
| | `LinkComponent` | `DefaultDocLink` | the host's router link, taking `to` |
| | `expandedSections` | none | the open sections' `href`s, when a caller owns the state; omit and the tree keeps its own |
| | `onToggleSection` | none | called with a section's `href` when its control is used; pass it with `expandedSections` |
| `DocNav` | `nodes` / `activePath` / `LinkComponent` | — | passed straight through to `DocNavTree` |
| | `topLinks` | `[]` | fixed `{ label, href }` rows above the tree; empty drops their divider too |
| | `open` | `false` | whether the mobile drawer is showing — controlled, always |
| | `onClose` | none | called from the close control and from the scrim |
| | `title` | `"Navigation"` | the drawer's heading |
| | `closeLabel` | `"Close navigation"` | accessible name for the drawer's close control; the scrim is `aria-hidden` and takes no name |
| `DocBreadcrumbs` | `crumbs` | — | `{ label, path }[]`, root-first; the last is the current page |
| | `homeLabel` | `"Home"` | label for the fixed first crumb |
| | `homeHref` | `"/"` | destination for the fixed first crumb |
| | `LinkComponent` | `DefaultDocLink` | the host's router link, taking `to` |
| `DocArticle` | `html` | — | pre-rendered, already-trusted document HTML |
| | `as` | `"article"` | `article` for a document, `div`/`section` for a fragment |
| `DocMetadata` | `fields` | — | `{ label, value }[]` in display order; an array `value` renders as a wrapping group |
| `DocTableOfContents` | `headings` | — | `{ id, text, depth }[]` in document order, as the host's loader extracted them |
| | `excludeIds` | none | ids to leave out; omit to list everything |
| | `title` | `"On this page"` | the rail's own label |
| `ViewSourceDisclosure` | `source` | — | the raw document text; rendered verbatim, never parsed |
| | `label` | `"View source"` | the trigger's text |
| | `defaultOpen` | `false` | start expanded; uncontrolled from then on |
| `useScrollSpy` | `ids` | — | element ids to watch, in document order |
| | `rootMargin` | `"-80px 0px -60% 0px"` | the band that counts as "here": discounts a sticky header at the top and the lower 60% |
| | `threshold` | `0` | any visible pixel counts |

⚠️ **`DocArticle` is trusted-input only.** `html` goes through
`dangerouslySetInnerHTML`, so it must be markup the host itself produced — a
build-time markdown render of files in its own repo, say. Never pass
user-submitted or third-party HTML without sanitising it first; HDV does no
escaping and cannot.

The host derives `crumbs` itself rather than HDV deriving them from a slug: every
site slices its URL space differently (cookbook title-cases domain segments; another
site would look labels up in a manifest), and deriving them here would bake one
site's URL convention into the toolkit.

