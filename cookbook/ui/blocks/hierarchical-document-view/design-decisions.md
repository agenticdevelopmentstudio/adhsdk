
- **Decision**: HDV is a new block family rather than a mode of
  `HierarchicalTopicDetail`.
  **Rationale**: `TopicDetailItem` is flat, so HTDV
  cannot represent a nested document tree without changing its core type; and the
  two lay out differently (stacked panes vs. one nested column). Forcing them
  together would couple two shapes that change for different reasons
  (`separation-of-concerns`).
  **Approved**: pending
- **Decision**: the router is injected as `LinkComponent`, and the current route
  arrives as a plain `activePath` string.
  **Rationale**: importing `next/link` would
  make the package unusable outside Next and untestable without a router harness.
  Passing `to` rather than `href` makes the adapter an explicit mapping instead of
  an accidental structural match with `<a>` (`explicit-over-implicit`).
  **Approved**: pending
- **Decision**: types are re-declared here rather than imported from
  `@adh-sdk/model`.
  **Rationale**: `model` is not in the consuming build's
  package filter, its `NavNode` lacks the fields HDV needs, and it also exports a
  whole alternate site-shell framework — depending on it would re-couple consumers,
  by the back door, to the lineage cookbook deliberately forked away from. Two type
  declarations is the cheaper, more reversible trade
  (`small-reversible-decisions`).
  **Approved**: pending
- **Decision**: `DocMetadata` takes rendered `{ label, value }` pairs, not a
  frontmatter object.
  **Rationale**: which fields exist, how they format, and which
  are links is site vocabulary. Keeping it out means adding a field to a site never
  touches the toolkit (`srp` — the block answers to layout, not to any one site's
  schema).
  **Approved**: pending
- **Decision**: the change-history table stays a second `DocArticle` rather than
  becoming a `DataTable`.
  **Rationale**: it arrives as markdown-rendered HTML inside
  the document; converting it would need a new loader-side GFM-table parser and
  would visibly change the rendered output — a redesign, which this extraction
  explicitly is not (`yagni`).
  **Approved**: pending
- **Decision**: the table of contents filters by an `excludeIds` prop rather than
  knowing which headings are chrome.
  **Rationale**: cookbook hides its change
  history because it relocates it below the frontmatter; another host will want it
  listed. Baking one site's convention in would make the block wrong for the second
  consumer, and the default — filter nothing — is the one with no opinion in it
  (`explicit-over-implicit`).
  **Approved**: pending
- **Decision**: `useScrollSpy` keys its effect on the ids' joined VALUE, not the
  array's identity.
  **Rationale**: every real caller derives its ids inline
  (`headings.filter(...)`), producing a fresh array each render; keying on identity
  would tear the observer down and rebuild it on every render, losing the marked
  heading. The site's original component sidestepped this by depending on an
  unfiltered prop, which is a coincidence rather than a contract
  (`principle-of-least-astonishment`).
  **Approved**: pending
- **Decision**: the rail's entry classes are composed with a template literal, not
  `cn()`.
  **Rationale**: `tailwind-merge` cannot reliably tell `border-l` (a width)
  from `border-[var(--color-accent)]` (a colour), and dropping either would cost the
  marker. Nothing merges a host class onto the entries, so `cn()` buys nothing there
  — it is still used on the root, where the host's `className` does merge.
  **Approved**: pending
- **Decision**: `ViewSourceDisclosure` does **not** compose the toolkit's existing
  `Disclosure`.
  **Rationale**: `Disclosure` is a framed card — rounded border,
  raised surface, padded header, `text-sm font-medium` title, a ruled content box —
  and that is exactly what its other consumers (the API
  explorer's three panels, the showcase, and a settings-pane danger-zone
  disclosure) want. This row is the opposite: a hairline
  rule *above* a mono micro-label, with an unframed `<pre>` beneath. Reaching it
  through `Disclosure` would mean cancelling every visual decision it makes — card
  chrome, header padding, chevron size and colour, title family/size/weight/colour,
  content frame: nine overrides to keep about twenty lines of open/close state, plus
  a standing coupling that would let a future `Disclosure` restyle silently break
  the document reader. When every visual property must be cancelled, you are paying
  a component's cost and taking none of its value. Two disclosures is not a `dry`
  violation either: `dry` is one representation per piece of *knowledge*, and a
  framed section and an inline text toggle are different knowledge
  (`srp` — `Disclosure` stays answerable to its card consumers alone).
  **Approved**: pending
- **Decision**: no `bare` / `contentClassName` escape hatches were added to
  `Disclosure`.
  **Rationale**: they were the plan of record until the two components
  were compared line by line. Once HDV stopped composing `Disclosure`, they would
  have been props with no caller — speculative surface on a primitive three things
  depend on (`yagni`).
  **Approved**: pending
- **Decision**: the chevron is lucide's `ChevronRight`, not the site's inline
  `<svg>`.
  **Rationale**: the toolkit already depends on lucide and every other
  block draws from it; copying a bespoke path in would fork the icon set. The cost
  is one pixel of glyph width at `h-3 w-3` (lucide's chevron spans 6 units of its
  24-unit box where the site's spanned 7) — the extraction's single recorded visual
  delta, named in the Overview so it reads as a decision rather than as drift.
  **Approved**: pending
- **Decision**: `aria-expanded` and `aria-controls` were added, which the site's
  button lacked.
  **Rationale**: a control that reveals a region must say so; the
  omission was a bug, and fixing it costs nothing visually. "A move, not a
  redesign" constrains the *rendering*, not the semantics.
  **Approved**: pending
- **Decision**: the panel is removed from the DOM when collapsed rather than hidden
  with CSS.
  **Rationale**: the source is the same text as the rendered document.
  Keeping a hidden copy would double every document's text for find-in-page, screen
  readers, and any crawler that ignores `display:none` (`explicit-over-implicit`).
  **Approved**: pending
- **Decision**: `ViewSourceDisclosure` owns the `<pre>` rather than taking
  `children`.
  **Rationale**: the panel's typography *is* part of the reader's
  contract, and every host revealing a document's source wants the same box. A
  `children` slot would push that decision to each site and let them drift
  (`dry`).
  **Approved**: pending
- **Decision**: only the top level of the tree collapses; every directory below it
  is always expanded.
  **Rationale**: the site's rules doc demanded "if a section has
  ANY sub-items, it MUST be toggleable. No exceptions" — and the site's code has
  never done that, because `DirLink` renders its children unconditionally. The code
  is right. Cookbook holds 466 documents, most at depth ≥ 3; a latch at every level
  makes reaching a page four clicks and makes a section the reader just opened still
  look empty. The rules doc was corrected to match the code, not the reverse
  (`principle-of-least-astonishment`).
  **Approved**: pending
- **Decision**: a section's expanded state is seeded from `activePath` at mount and
  owned by the reader afterwards.
  **Rationale**: deriving it on every render is the
  obvious implementation and it is wrong — it slams a section shut under a reader
  who opened it to browse while standing on a page elsewhere. Seeding once is the
  only version where the control does what its user just asked it to.
  **Approved**: pending
- **Decision**: the tree re-sorts a node's children — pages before directories —
  rather than honouring the host's array order.
  **Rationale**: this is the site's
  existing behaviour (`NavSection` and `DirLink` each partition their children), and
  it is what makes every level scan the same way. Making it a prop would be surface
  with no caller (`yagni`); if a host ever needs its own order, deleting the
  partition is a smaller change than removing a knob.
  **Approved**: pending
- **Decision**: the mobile drawer's `open` is controlled, with no uncontrolled
  fallback.
  **Rationale**: the button that opens it is in the site header, outside
  HDV's subtree. An uncontrolled drawer would compile, render, and test green while
  the header's hamburger did nothing (`explicit-over-implicit`).
  **Approved**: pending
- **Decision**: `onClose`, not `onOpenChange`.
  **Rationale**: nothing inside
  `DocNav` ever opens the drawer — the opener is the host's. A callback that can
  only ever be called with `false` should not take an argument
  (`explicit-over-implicit`).
  **Approved**: pending
- **Decision**: `HdvNavNode` has no `id` and no `trailing` slot, and its `href` is
  required.
  **Rationale**: all three were in the plan of record. `href` already
  identifies a node uniquely — it is a URL — so an `id` would be a second key to
  keep in step; no host has a badge to hang on a nav row; and every node in a
  document tree is a real page, since a directory is its own index. Admitting a
  destination-less group would put an `href ? link : span` branch at three levels of
  the tree to serve a shape nothing produces. All three are additive later
  (`yagni`).
  **Approved**: pending
- **Decision**: there is no `collapsibleDepth` knob.
  **Rationale**: its only honest
  values are "top level only" — what every host wants — and "all levels", what
  nothing wants per the decision above. If uniform toggling ever becomes right, the
  change is to delete the level switch, not to expose it as configuration.
  **Approved**: pending
- **Decision**: the site's `data-autoscroll="true"` attribute on the nav is dropped.
  **Rationale**: nothing in the repo reads it — no CSS rule, no script, no test. It
  was a hook for a scroll-into-view behaviour that was never built
  (`design-for-deletion`).
  **Approved**: pending
- **Decision**: cookbook's `decisionHeadings` side-channel is deleted rather than
  ported.
  **Rationale**: it was dead code, verified against the built HTML — no page
  contained an outline anchor — because `showHeadings` was passed only from a
  top-level section to its direct leaves when that section's path was
  `/appendix/decisions`, and a top-level section's path is always `/<section>`.
  Porting a feature that never rendered would be inventing one. HDV keeps the
  `headings` capability, tested and documented, for the first host that wants it;
  whether cookbook should now turn its ADR outlines **on** is a visible product
  change and the site owner's call, not the extraction's.
  **Approved**: pending
- **Decision**: a mid-tree directory renders its link and its child list as two
  SIBLING `<li>`s rather than nesting the list inside the item.
  **Rationale**: this
  is the site's markup and it is load-bearing — the child list's rule starts at the
  parent's left edge instead of inside its list item, which is what makes the rails
  stack one indent apart down the column. Nesting would shift every rule right by a
  text indent.
  **Approved**: pending
- **Decision**: the site's three mutually-recursive nav functions (`NavSection`,
  `DirLink`, `FileLink`) collapse into one recursive component whose rendering is
  chosen by depth and by `children.length`.
  **Rationale**: the three shared a
  `showHeadings` side-channel and duplicated the pages-before-directories partition
  twice; one component keyed on where a node *sits* has a single copy of each
  (`dry`, `simplicity`).
  **Approved**: pending
- **Decision**: `DocBreadcrumbs` takes resolved crumbs instead of a slug.
  **Rationale**: slug→label is a per-site URL convention; deriving it here would
  make the toolkit wrong for the second consumer (`dry` — the convention has one
  home, in the site that owns the URLs).
  **Approved**: pending

- **Decision**: the frame is two components — `HierarchicalDocumentView` and
  `DocPage` — rather than one taking three slots.
  **Rationale**: the three columns
  do not live in one place. The nav persists across navigations and belongs to the
  host's layout; the article and rail are the page. A single component taking all
  three would force the nav into the page, remounting the tree on every route change
  and resetting the reader's expanded sections. The split follows the React boundary
  that already exists (`separation-of-concerns`), and the seam is where the host
  already has one.
  **Approved**: pending
- **Decision**: the content region is a `div` and the frames render no landmark.
  **Rationale**: the site nested a second `main` inside its app shell's, which is
  invalid; baking that into the toolkit would spread it to every consumer. Landmarks
  are a whole-page concern the host owns, and HDV cannot know where the page's main
  region begins (`separation-of-concerns`, `principle-of-least-astonishment`).
  **Approved**: pending
- **Decision**: the frames take slots and a `className`, and nothing else — no
  `contentClassName`, no `articleClassName`, no configurable gap.
  **Rationale**: the
  exported class constants are the escape hatch already, and every knob added here is
  a way for a consumer to disagree with the measure that is the block's reason to
  exist (`yagni`, `simplicity`).
  **Approved**: pending
- **Decision**: a slotted column is rendered unwrapped.
  **Rationale**: `DocNav` and
  `DocTableOfContents` are `sticky` with their own header-height offsets, which
  resolve against their sticky containing block. Any wrapper the frame added — even
  a bare, non-scrolling `div` — would silently become that containing block, clamping
  how far the column can stick to the wrapper's own bounds, and both columns would
  stop holding position with no error to explain it (`explicit-over-implicit`).
  **Approved**: pending

