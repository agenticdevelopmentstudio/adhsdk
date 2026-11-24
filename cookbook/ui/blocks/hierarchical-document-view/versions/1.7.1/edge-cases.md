
- **A tree 466 documents deep in places.** Only the top level latches. Cookbook's
  guidelines section alone holds hundreds of pages at depth ≥ 3; a control at every
  level would turn reaching one into four clicks, and a section the reader had just
  opened would still look empty. They pick a section; everything inside it is then
  visible.
- **A section the reader closed, and then navigated inside.** It stays closed. The
  state is derived once, at mount, and is theirs from then on.
- **A node with children whose `href` is also a real page.** A directory is both:
  its own link, then its contents. Cookbook's `/principles` is a section index page
  *and* a parent.
- **A host that sorted its nodes.** HDV re-sorts anyway — pages before directories,
  at every level — so the tree scans the same way whatever order arrives. A host
  wanting its own order has to ask, and none has (`yagni`).
- **`activePath` with a trailing slash or a query string.** Matching is exact string
  equality against `href`; anything else is simply not the active page. The host
  normalises before passing — cookbook's `usePathname()` already yields the
  canonical path.
- **No `topLinks`.** The rows and their divider both disappear, so a site whose
  whole nav is the tree gets a clean column rather than a rule with nothing above
  it.
- **The drawer's opener lives in the site header.** That is why `open` is
  controlled. An uncontrolled drawer would compile, render, and unit-test green
  while the header's hamburger did nothing — the single most likely way to get this
  component wrong, and not catchable by `DocNav`'s own tests.
- **A leaf whose `headings` name ids that are not on the page.** The click falls
  through to the anchor's default and the browser does nothing. HDV does not own the
  document, so it cannot assert the element is there.
- **The cookbook's ADR outlines.** The site's `decisionHeadings` plumbing was dead
  on arrival: `showHeadings` was passed only from a top-level section to its direct
  leaves, gated on the path `/appendix/decisions` — and a top-level section's path
  is always `/<section>`, so the gate never fired. No built page ever contained an
  outline anchor. The extraction therefore renders what the site rendered (nothing)
  and deletes the dead plumbing; `headings` stays as a capability for the first host
  that actually wants it.
- **A document set with no tree.** Omit `nav` and the frame is a single-column reader; nothing renders an empty 20rem gutter. Same for `toc` — a document with no headings gets the full width, because `DocTableOfContents` already returns nothing and the frame adds no wrapper around it.
- **A host whose app shell already renders `main`.** Every one in this family does, which is why the frame renders a `div`. A host that has *no* landmark wraps HDV in its own `main` — one line, and it owns where the landmark starts, which HDV cannot know.
- **Site root.** `crumbs: []` hides the whole nav — a lone "Home" pointing at the
  page you are on is noise, not navigation.
- **A document with no change history.** The host's split returns an empty second
  half and simply renders one `DocArticle`; HDV has no opinion about the split.
- **A frontmatter field whose value is a list.** References and tags wrap
  right-aligned rather than pushing the row off the edge.
- **Non-URL citations.** Books and papers are cited in prose ("Osborn, *Applied
  Imagination*, 1953"); an `<a href>` around one points nowhere, so the host decides
  per item whether it is a link. HDV renders whatever nodes it is given.
- **Heading ids.** Anchors come from the host's markdown slugger (cookbook uses
  `rehype-slug`). HDV takes them as given — a change to that slug config silently
  breaks scroll-to-heading without HDV changing.
- **Untrusted HTML.** `DocArticle` uses `dangerouslySetInnerHTML` and does no
  escaping. See Configuration.
- **A document with one heading.** The rail still renders — a one-entry outline is
  the honest answer, and suppressing it would make the layout jump between pages.
- **A heading id with no element.** The spy skips it; the entry still renders and
  its anchor simply does nothing. HDV does not own the document, so it cannot
  assert the element exists.
- **Two headings visible at once.** The FIRST in `ids` order wins — the reader's
  position is the topmost heading they can see. Taking the last one the observer
  mentioned instead makes the marker depend on scroll direction and on batching:
  a callback reports only what CHANGED, so scrolling up (where the heading that
  changed is the *higher* one) and scrolling down disagree about the same viewport.
- **No heading visible at all.** The marker holds its last position. A reader
  between two headings, or inside one long section, is still somewhere — clearing
  the rail there would blank it for most of a long document.
- **A host that renders its own headings client-side.** The spy resolves elements
  by id when it subscribes; content appearing later is not observed until the ids
  change.
- **A document whose source contains HTML.** `ViewSourceDisclosure` is the one
  block in the family that does *not* trust its input: the source is a text child
  of a `<pre>`, so markup is shown rather than executed. It is safe to point at
  content `DocArticle` would not be.
- **A very long source.** The panel grows with the document rather than scrolling
  internally — the reader who asked for the source wants all of it, and a nested
  scroll region inside a scrolling page is a trap. Only over-wide lines scroll.
- **An empty source.** The panel still renders. A document with no body still has
  a source, and a toggle that opened onto nothing would read as broken.
- **A host that wants the source open by default.** `defaultOpen` seeds the state;
  the reader owns it from then on. There is deliberately no controlled mode until
  a host needs one (`yagni`).

