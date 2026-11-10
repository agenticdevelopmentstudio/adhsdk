
**HDV** (Hierarchical Document View) is the family's long-form **document reader**:
a three-column layout of a collapsible multi-depth nav tree, a prose centre column
(breadcrumbs → article → frontmatter → change history → view-source), and a
scrollspy table of contents. It is extracted from the cookbook site, which had the
best reader in the family trapped inside one Next app.

HDV is **not** a variant of `HierarchicalTopicDetail`. HTDV's `TopicDetailItem` is
flat — it has no `children` — so it structurally cannot render a nested document
tree; and HTDV stacks *panes* horizontally where HDV nests *one* tree vertically at
arbitrary depth with per-branch collapse. They are different shapes that happen to
share the word "hierarchical".

**The reader landed in stages**, completed in 1.4.0, then hardened in 1.5.x:

| Component | Status |
|---|---|
| `DocBreadcrumbs`, `DocArticle`, `DocMetadata` | 1.0.0 |
| `DocTableOfContents` + `useScrollSpy` | 1.1.0 |
| `ViewSourceDisclosure` | 1.2.0 |
| `DocNavTree` / `DocNav` | 1.3.0 |
| `HierarchicalDocumentView` + `DocPage` (the frame) | 1.4.0 |
| Hardening: shared drawer collapse state, one announced dismiss control, ordered scrollspy, no dangling `aria-controls` | 1.5.0 |
| Platform Notes restructured per platform | 1.5.1 |

The governing constraint for the whole extraction is that **it is a move, not a
redesign**: every default here byte-matches what the cookbook site rendered before
it, so a visual delta is a bug rather than a judgement call. Redesign happens later,
on a green base.

There are exactly **two** recorded exceptions to that byte-match, recorded
precisely so they are not drift — and only one of the two is visible.

**The chevrons.** Every one is lucide's `ChevronRight` rather than the site's
hand-rolled inline `<svg>` — `ViewSourceDisclosure`'s and the nav section's
collapse control. Same box, same stroke width, same rotation — the glyph itself is
one pixel narrower at `h-3 w-3`. Copying a bespoke icon path into a toolkit that
already depends on lucide would duplicate knowledge lucide owns (`dry`); the pixel
is the price, and it is named here rather than discovered later.

**The content region is a `div`, not a `main`.** The site wrapped the document
region in `<main className="flex-1 min-w-0">` — *inside* the `main` its shared
`AppShell` already renders. Two nested `main` landmarks is invalid HTML, and
extracting the frame forced the choice: rendering a `main` here would bake the bug
into every future consumer. So the frame renders a `div` and the host keeps its one
landmark. Zero visual delta (both are `display: block`), one element name changed,
and one pre-existing a11y defect gone.

The nav column's parity was **measured, not asserted**, against the pre-extraction
production build — see Change History 1.3.0 for the pages sampled and the byte
delta, which resolves to exactly the four intended changes named there: the lucide
chevron above, a dropped `data-autoscroll` attribute nothing read, and the
`type="button"` and `aria-expanded` the original toggle lacked.

Three seams keep site vocabulary out of the toolkit:

- **Routing.** HDV never imports `next/link` or `next/navigation`. A host injects
  its router as `LinkComponent` (a component taking `to`, not `href`) and tells HDV
  which page is current with a plain `activePath` string. The default is a bare
  `<a href>`, so a non-Next app needs no adapter at all.
- **Vocabulary.** HDV lays a frontmatter block out; it never decides what a
  document's frontmatter *contains*. The host maps its own fields to a list of
  label/value pairs.
- **Chrome.** HDV lists every heading it is given. Which headings are *chrome*
  rather than argument — a change history, a licence footer — is the host's call,
  made by naming ids in `excludeIds`. Omit it and nothing is filtered.

