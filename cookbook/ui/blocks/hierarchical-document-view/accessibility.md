
- Each section's collapse control is a real `button` with `type="button"` and
  `aria-expanded`, labelled "Expand <section>" / "Collapse <section>" — the label
  names the section, so a screen-reader user moving through six controls in a row
  can tell them apart. The site's original toggle carried neither `type` nor
  `aria-expanded`; adding both is a deliberate improvement with no visual delta.
- Exactly one node in the tree carries `aria-current="page"`. The accent bar
  beside it is decoration; the attribute is what is announced.
- A directory is a link *and* a parent, so it is announced once — as a link —
  with its children as the list that follows rather than as items nested inside
  it. The tree does not read as doubly nested.
- Inlined headings are ordinary `href="…#id"` anchors, so they work with
  JavaScript off; the click handler only upgrades a same-page jump to a smooth
  scroll, and writes the hash so the position stays linkable.
- The drawer's scrim dismisses on click, but it is an `aria-hidden` `div` with no
  tab stop and no name — so the drawer offers assistive tech exactly ONE control
  named `closeLabel`. An earlier draft made the scrim a named `button` instead,
  which announced two identical controls for one action and put a viewport-sized
  button over the document; keyboard dismissal is already served by the close
  control in the drawer's own header, and by `Escape` from the host's trigger.
- The drawer is absent from the DOM when closed rather than hidden, so its links
  are never in the tab order behind the page.
- Neither frame renders a landmark. The nav column brings its own `aside` and `nav`, the rail its own `aside`, and the page's single `main` belongs to the host's app shell — so a screen-reader user gets one main region and three named ones, not a nested pair of mains.
- The breadcrumb trail is a `nav` labelled `Breadcrumb`, so assistive tech
  announces it as the trail rather than as generic links.
- The current page is a `span`, not a link — there is no self-referential link to
  land on, and the trail's end is unambiguous.
- The `/` separators are text inside the list item; they carry no role and are not
  announced as interactive.
- The frontmatter block is a real `dl`/`dt`/`dd`, so each value is announced with
  its label rather than as a run of loose text.
- Reference links that open a new tab carry `rel="noopener noreferrer"` — supplied
  by the host, since the host owns the link nodes.
- `DocArticle`'s heading structure comes from the host's rendered HTML; HDV adds no
  headings of its own and so cannot break the document outline.
- The table of contents is a real list of real `href="#id"` anchors, so it works
  with JavaScript disabled and is keyboard-navigable by default. The click handler
  only upgrades the jump to a smooth scroll.
- `prose-headings:scroll-mt-20` keeps a scrolled-to heading clear of the sticky
  header, so a keyboard user landing on an anchor sees the heading rather than the
  text beneath it.
- The marked entry is styled, not `aria-current`: the rail reflects scroll
  position, which changes continuously and is not a navigation state a screen
  reader should announce on every pixel.
- The view-source trigger is a real `button` carrying `aria-expanded` and
  `aria-controls`, so assistive tech announces both that it expands something and
  what. The site's original button carried neither — this is a deliberate
  improvement on extraction, with no visual delta.
- Its chevron is `aria-hidden`: the trigger's text already names the action, and
  the rotation is redundant with `aria-expanded`.
- The source panel is removed from the DOM when collapsed rather than hidden with
  CSS, so the document's text is never announced twice or matched twice by
  find-in-page.

