
| Component | State | Rendering |
|---|---|---|
| `DocNavTree` | section outside the active page | closed; chevron unrotated |
| `DocNavTree` | section containing, or equal to, the active page | open on mount |
| `DocNavTree` | section the reader toggled | stays as they left it across route changes |
| `DocNavTree` | directory at depth ≥ 1 | always expanded; no control rendered |
| `DocNavTree` | node whose `href` is `activePath` | `aria-current="page"`, bold, accent bar |
| `DocNavTree` | node that is an ancestor of the active page | `font-medium`, no bar, no `aria-current` |
| `DocNavTree` | leaf with no `headings` | link only; no sub-list in the DOM |
| `DocNav` | `topLinks` empty or omitted | no fixed rows **and** no divider |
| `DocNav` | `open: false` | the desktop aside only — no drawer, no backdrop |
| `DocNav` | `open: true` | aside + backdrop + drawer, the same nav in both shells |
| `HierarchicalDocumentView` | `nav` omitted | one child, the content region — no empty column |
| `HierarchicalDocumentView` | `nav` given | the column, then the content region, as siblings |
| `DocPage` | `toc` omitted | the document column alone, at full width of the region |
| `DocPage` | `toc` given | the document at its measure, the rail beside it |
| `DocBreadcrumbs` | trail non-empty | home + crumbs, last as text |
| `DocBreadcrumbs` | `crumbs: []` (site root) | renders nothing |
| `DocBreadcrumbs` | crumb link hover | text lifts dim → secondary |
| `DocArticle` | `html: ""` | an empty prose container (the host decides whether to render it) |
| `DocMetadata` | `fields: []` | renders nothing |
| `DocMetadata` | array value | items wrap right-aligned across lines |
| `DocTableOfContents` | no heading survives filtering | renders nothing |
| `DocTableOfContents` | before any heading is reached | every entry unmarked |
| `DocTableOfContents` | a heading enters the band | that entry marked, the previous one cleared |
| `DocTableOfContents` | viewport below `xl` | hidden |
| `ViewSourceDisclosure` | collapsed (default) | rule + trigger only; no panel in the DOM |
| `ViewSourceDisclosure` | expanded | chevron rotated 90°, `<pre>` panel below the trigger |
| `ViewSourceDisclosure` | `source: ""` | an empty panel — a document with no body still has a source |

`HierarchicalDocumentView`, `DocPage`, `DocBreadcrumbs`, `DocArticle`, and
`DocMetadata` are pure and stateless — no internal state, no effects, and therefore
no `"use client"` boundary; they render identically on the server and the client.
The two frames hold no props but their slots and a `className`, which is why they
can sit in a server layout with a client tree passed into them. `DocTableOfContents` is a client
component: it holds the marked id and subscribes an `IntersectionObserver`. It
server-renders its full list with nothing marked, so the outline is in the HTML
before hydration. `ViewSourceDisclosure` is a client component too, but holds only
open/closed state — it server-renders its rule and trigger, collapsed.

`DocNavTree` is a client component carrying one open/closed boolean per top-level
section, and it server-renders the tree with the active section **already open** —
so a reader's first paint is the correct tree, not a closed one that expands on
hydration. It holds that state itself when it stands alone, and takes it from above
(`expandedSections` + `onToggleSection`) when something has to share it.

`DocNav` is that something. Its desktop column and its drawer are two component
INSTANCES of one element description, so each would otherwise keep its own copy of
the expansion state — and the drawer's would be destroyed with the drawer, silently
losing whatever the reader had just opened. `DocNav` therefore owns the state and
hands the same one to both shells. The drawer's `open` still belongs to the host,
because the control that opens it does.

