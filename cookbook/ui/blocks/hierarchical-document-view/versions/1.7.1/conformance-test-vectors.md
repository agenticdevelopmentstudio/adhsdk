
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | hide-empty-trail | `<DocBreadcrumbs crumbs={[]} />` | nothing rendered |
| T2 | render-crumbs-in-order | 2 crumbs | 3 `li` (home + 2) and exactly 2 `/` separators |
| T3 | render-current-page-as-text | 2 crumbs | links are `/` and the first crumb's path; the last crumb is a `span` |
| T4 | route-through-injected-link | a `LinkComponent` marking its output | every link carries the adapter's marker, and HDV's `className` survives its prop spread |
| T5 | accept-a-relabelled-home | `homeLabel="Docs" homeHref="/docs"` | first crumb reads "Docs" and points at `/docs` |
| T6 | render-trusted-html | `html="<h2 id='intro'>Intro</h2><p>Body</p>"` | an `article` containing an `h2#intro` and the body text |
| T7 | expose-the-prose-contract | `<DocArticle html="" />` | `className` equals `DOC_ARTICLE_PROSE_CLASS` exactly (nothing rewrote or reordered it) |
| T8 | honor-article-element | `as="div"` | the root is a `div` |
| T9 | hide-empty-metadata | `<DocMetadata fields={[]} />` | nothing rendered |
| T10 | render-one-row-per-field | 2 fields | `dt` text in order; `dd` text in order; `dt` dim, `dd` secondary |
| T11 | group-list-values | an array of 2 nodes | one `dd > span.flex.flex-wrap.justify-end.gap-x-3` with 2 children |
| T12 | group-list-values | a scalar value | no wrapping `span` inside the `dd` |
| T13 | spread-host-attributes | `data-testid` on each | the attribute lands on the root element |
| T14 | list-every-heading-by-default | 3 headings, no `excludeIds` | all 3 listed, including one a host would call chrome |
| T15 | omit-excluded-headings | `excludeIds={['change-history']}` | 2 listed, and exactly those 2 elements observed |
| T16 | hide-empty-outline | `headings={[]}`; and every id excluded | nothing rendered, both times |
| T17 | indent-by-depth | depth 2 and depth 3 | `pl-3` and `pl-6` respectively; `href` is `#<id>` |
| T18 | mark-the-current-heading | drive the observer to heading B | B accented and bold; A still `border-transparent` |
| T19 | scroll-not-navigate | click an entry | the click is default-prevented and `scrollIntoView({behavior:'smooth'})` is called |
| T20 | track-by-id-value | re-render with an equal-valued NEW ids array | one observer total; the marked id survives |
| T21 | track-by-id-value | re-render with DIFFERENT ids | the first observer is disconnected and a second observes the new set |
| T22 | observe-only-existing-elements | an id with no element; then unmount | only the real element is observed; the observer disconnects |
| T23 | start-collapsed | `<ViewSourceDisclosure source={md} />` | no `pre` in the DOM and the source text is not present |
| T24 | toggle-both-ways | click, then click again | the panel appears with the source, then is removed |
| T25 | toggle-both-ways | `defaultOpen` | the panel is present on first render |
| T26 | render-source-verbatim | a source containing `<script>` | the panel's text equals the source; it has zero child ELEMENTS |
| T27 | announce-its-state | before and after activation | `aria-expanded` flips `false`→`true`; `aria-controls` equals the panel's non-empty `id` |
| T27b | announce-its-state | collapsed, expanded, collapsed again | `aria-controls` is ABSENT both times the panel is — no dangling IDREF |
| T28 | toggle-both-ways | activate | the chevron gains `rotate-90` only while open |
| T29 | spread-host-attributes | default, then `label` | the trigger reads "View source", then the host's label |
| T30 | spread-host-attributes | `data-testid`, `defaultOpen` | row, trigger, and panel `className`s equal their exported contracts EXACTLY |
| T31 | toggle-both-ways | `source=""` with `defaultOpen` | the panel renders and is empty — not absent |
| T32 | collapse-only-the-top-level, open-the-active-section | `activePath="/"` | the section's children are absent; its control reads `aria-expanded="false"` and is named "Expand Principles" |
| T33 | open-the-active-section | `activePath` = a depth-3 page | that section's pages are present; the sibling section's are not |
| T34 | open-the-active-section | `activePath` = the section itself | the section is open |
| T35 | collapse-only-the-top-level | click Expand, then Collapse | children appear, then vanish; the chevron carries `rotate-90` only while open |
| T36 | keep-the-readers-collapse-state | open a section, then re-render with a DIFFERENT `activePath` | the section is still open |
| T37 | collapse-only-the-top-level | a directory at depth 1 | its children render, and there are exactly 2 buttons — one per section, none for the directory |
| T38 | mark-the-active-page | `activePath` = a depth-3 leaf | exactly one link carries `aria-current="page"`, and it is that leaf |
| T39 | mark-the-active-page | re-render with a new `activePath` | the mark leaves the old page and lands on the new one |
| T40 | list-pages-before-directories | a host array with the directory FIRST | the rendered order is page, directory, directory's page |
| T41 | route-through-injected-link | a `LinkComponent` marking its output | every link in the tree carries the adapter's marker |
| T42 | collapse-only-the-top-level | inspect the two lists | their `className`s equal `DOC_NAV_SECTION_LIST_CLASS` and `DOC_NAV_BRANCH_LIST_CLASS` exactly |
| T43 | inline-supplied-headings | a leaf with 2 headings | both render, and the first's `href` is `<leaf>#<id>` |
| T44 | inline-supplied-headings | a leaf with none | no sub-list under its link |
| T45 | scroll-when-already-on-the-page | click a heading while its page is active | default-prevented, `scrollIntoView({behavior:'smooth'})`, and `replaceState(null,'',<leaf>#<id>)` |
| T46 | scroll-when-already-on-the-page | click that heading from another page | NOT default-prevented, and no `replaceState` |
| T47 | drop-the-divider-with-the-rows | 2 `topLinks` | the rows render and there is exactly one `nav > div.border-t` |
| T48 | drop-the-divider-with-the-rows | `topLinks` omitted | zero `nav > div.border-t` |
| T49 | mark-the-active-page | `activePath` equal to a fixed row's `href` | exactly one accent bar, inside that row's `h3` |
| T50 | control-the-drawer | `open` omitted | one `aside`, whose `className` equals `DOC_NAV_ASIDE_CLASS`; the `nav`'s equals `DOC_NAV_NAV_CLASS` |
| T51 | share-one-nav | `open` | two `aside`s in order [aside, drawer], and two `nav`s |
| T52 | control-the-drawer, announce-one-dismiss-control | click the scrim, then the close control | exactly ONE announced control named "Close navigation"; the scrim is an `aria-hidden` `div` with no `tabindex`; `onClose` fires twice |
| T53 | control-the-drawer | `title="Contents" closeLabel="Dismiss"` | the drawer reads "Contents" and there is exactly ONE control named "Dismiss" |
| T54 | spread-host-attributes | `className="w-96"` + `data-testid` | the column keeps `sticky`, carries `w-96`, has no `w-80`, and the attribute lands on it |
| T55 | place-the-nav-before-the-document | `nav` + children | 2 children: the nav node itself, then a region whose class equals `HIERARCHICAL_DOCUMENT_VIEW_CONTENT_CLASS` and which holds the document |
| T56 | slot-columns-unwrapped | `nav` | the nav's `parentElement` is the frame itself, so its `sticky` resolves against the frame |
| T57 | drop-an-omitted-column | no `nav` | exactly 1 child, the content region |
| T58 | render-no-landmark | `nav` + children | no `main` element and no `main` role anywhere in the output |
| T59 | spread-host-attributes | `className="gap-4"` | the frame keeps `flex-1` and gains `gap-4` |
| T60 | spread-host-attributes | `id` + `data-*` | both land on the frame |
| T61 | place-the-nav-before-the-document, cap-the-measure | `toc` + children | 2 children: the measure column holding the document, then the rail node |
| T62 | cap-the-measure | `<DocPage>{doc}</DocPage>` | `DOC_PAGE_ARTICLE_CLASS` contains both `max-w-3xl` and `min-w-0` |
| T63 | drop-an-omitted-column | no `toc` | exactly 1 child, the measure column |
| T64 | slot-columns-unwrapped | `toc` | the rail's `parentElement` is the row itself |
| T65 | spread-host-attributes | `className="items-start"` + `id` | the row keeps `flex`, gains `items-start`, and carries the `id` |
| T66 | slot-columns-unwrapped | a `DocPage` inside a `HierarchicalDocumentView` | nav → content region → row → measure → document, with the rail on the row and the nav on the frame — neither frame reaches into the other |
| T67 | mark-the-current-heading, carry-visibility-across-callbacks | ONE callback reporting `c`, `a`, `b` as entering together | `a` is marked — the first in `ids` order, not the last reported |
| T68 | carry-visibility-across-callbacks | `a` enters; `b` enters in a SECOND callback; then `a` leaves | `a`, still `a`, then `b` — `b`'s visibility survived a callback that never mentioned it |
| T69 | hold-the-last-position | the only visible heading leaves the band | the marker stays where it was rather than clearing |
| T70 | carry-visibility-across-callbacks | DOM order `b`, `a` with `ids = ['a','b']` | `a` is marked — document order comes from `ids`, not from the DOM |
| T71 | share-one-nav | expand a section in the drawer, then close the drawer | the desktop column's section is still expanded |
| T72 | route-through-injected-link | a leaf's inlined `headings` with a `LinkComponent` | the heading anchors carry the adapter's marker too — a heading link is a route, not a document load |

