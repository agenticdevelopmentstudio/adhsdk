
The centre column is a `max-w-3xl` prose measure. Every colour is a flat
`--color-*` token from the shared ADH theme — the same contract
a host theme package provides to every site in the family — so HDV inherits
the host's palette without a per-site restyle.

```
 OVERVIEW      │ Home / Principles / Simplicity   ← DocBreadcrumbs      │ ON THIS PAGE
 PROJECTS      │ ─────────────────────────────────                      │
 ───────────   │ # Simplicity                     ← DocArticle          ┃ Simplicity ← marked
 ˅ PRINCIPLES  │ Body prose, headings, code, tables…                    │   In practice
 ┃ Overview    │                   version 1.3.0  ← DocMetadata         │
 │ Testing     │                 modified 2026-07-29                    │  ↑ DocTableOfContents
 │ │ Pyramid   │               references a.com  b.com                  │    (w-56, sticky)
 ˃ APPENDIX    │ ## Change History                ← a SECOND DocArticle │
               │ | Version | Date | … |             (host splits)       │
 ↑ DocNav      │ ─────────────────────────────────                      │
   (w-80, +    │ › View source                    ← ViewSourceDisclosure│
    DocNavTree)│                                                        │
```

- The frame is two nested flex rows and nothing else. The outer one (`HIERARCHICAL_DOCUMENT_VIEW_CLASS`) is `flex flex-1`, its content region (`HIERARCHICAL_DOCUMENT_VIEW_CONTENT_CLASS`) `flex-1 min-w-0`; the inner one (`DOC_PAGE_CLASS`) is `flex`, its document column (`DOC_PAGE_ARTICLE_CLASS`) `flex-1 min-w-0 px-6 py-8 lg:px-10 max-w-3xl`. The `max-w-3xl` is the whole reason the frame is shared: prose set to the full width of a 1440px window is unreadable, and `min-w-0` is what stops a wide table from shoving the rail off the edge.
- Nav column: `aside.hidden.lg:block w-80 shrink-0 border-r
  border-[var(--color-border-subtle)] overflow-y-auto sticky
  top-[var(--adh-header-height,3.5rem)]
  h-[calc(100vh-var(--adh-header-height,3.5rem))]` — sticky under the family's header
  and scrolling on its own, so a 466-page tree never pushes the document down. The
  offset **reads** `--adh-header-height` rather than restating it: that header is a
  bar plus a full-width preview strip above it, so any literal is a copy that goes
  stale the next time it grows. The `3.5rem` fallback is the bar alone, for the
  consumers of this package that mount no adh header at all. The `nav` inside is
  `flex flex-col gap-6 px-6 py-6 overflow-y-auto h-full`, and the same element is
  rendered into the drawer.
- Fixed rows: `h3.relative font-mono text-xs font-medium uppercase tracking-widest
  text-[var(--color-accent)] transition-colors`, its link hovering to
  `text-[var(--color-accent)]`; the active row carries an absolutely-positioned
  `-left-6 w-0.5 bg-[var(--color-accent)]` bar that sits out in the column's
  padding, clear of the text. Their divider is a lone
  `div.border-t border-[var(--color-border-subtle)]`.
- Section: a `flex items-center gap-1` row of a `p-0.5` chevron button — `h-3 w-3
  shrink-0 transition-transform duration-150` at `strokeWidth={2.5}`, gaining
  `rotate-90` while open — and a label sharing the fixed rows' type exactly. Its
  child list is `flex flex-col border-l border-[var(--color-border)] mt-1`; every
  list below that is the same rule indented past its parent's text, `ml-3.5`, so the
  rails stack one indent apart down the column.
- Entries: a leaf is `relative block py-0.5 text-sm transition-colors`, a mid-tree
  directory `py-1` — one notch more air where the tree branches. Selected is
  `font-semibold text-[var(--color-text-primary)]` plus a `w-px
  bg-[var(--color-accent)]` bar down its own left edge; an ancestor of the active
  page is `font-medium text-[var(--color-text-primary)]`; everything else is
  `text-[var(--color-text-secondary)]` hovering to primary. Links and inlined
  headings share one `padding-inline-start: 0.875rem`, so their text lines up
  whatever depth they sit at.
- Inlined headings: `relative block py-0.5 text-xs text-[var(--color-text-dim)]`
  hovering to secondary — a notch smaller and dimmer than the page links they hang
  under, so an outline never competes with the tree.
- Drawer: `div.fixed.inset-0.z-50.lg:hidden` holding a full-bleed `bg-black/50`
  scrim (`div[aria-hidden]`, click-to-dismiss) and `aside.fixed.inset-y-0.left-0 w-72
  bg-[var(--color-surface)] shadow-xl overflow-y-auto`, headed by
  `flex items-center justify-between px-6 py-4 border-b
  border-[var(--color-border-subtle)]` with a `font-mono text-sm font-medium` title
  and a lucide `X` at `h-5 w-5`. The panel is `w-72` where the desktop column is
  `w-80` — a drawer leaves the page behind it visible.
- Breadcrumbs: `nav[aria-label="Breadcrumb"] mb-4` → `ol.flex.items-center.gap-1
  font-mono text-xs text-[var(--color-text-dim)]`; separator
  `text-[var(--color-border)]`; current page `text-[var(--color-text-secondary)]`;
  links hover to `text-[var(--color-text-secondary)]`.
- Article: `prose max-w-none prose-headings:scroll-mt-20
  prose-code:before:content-none prose-code:after:content-none`. The
  `scroll-mt-20` is load-bearing — it keeps a heading clear of the sticky header
  when the ToC scrolls to it.
- Metadata: `dl.flex.flex-col.items-end.gap-0.5 font-mono text-[11px] mb-6`; rows
  `flex gap-2`; `dt` dim, `dd` secondary; a list value wraps in
  `flex flex-wrap justify-end gap-x-3`.
- Table of contents: `aside.hidden.xl:block w-56 shrink-0 sticky
  top-[var(--adh-header-height,3.5rem)]
  h-[calc(100vh-var(--adh-header-height,3.5rem))] overflow-y-auto py-8 pr-4`; header
  `font-mono text-[10px] font-medium uppercase tracking-widest
  text-[var(--color-text-dim)] mb-3`; list
  `flex flex-col gap-1 border-l border-[var(--color-border-subtle)]` with each
  `li` pulled back `-ml-px` so its own left border sits *on* the rail. Entries are
  `block border-l py-0.5 text-sm transition-colors` + `pl-3` (depth ≤ 2) or `pl-6`
  (depth 3); marked entries add
  `border-[var(--color-accent)] text-[var(--color-text-primary)] font-medium`,
  unmarked ones `border-transparent text-[var(--color-text-dim)]`.
- The rail is desktop-only (`hidden xl:block`): below `xl` there is no room beside
  a `max-w-3xl` measure, and the document's own headings are the outline.
- View source: the row is `mt-8 border-t border-[var(--color-border-subtle)] pt-4`
  — a hairline rule *above* the trigger, separating it from the document rather
  than framing it. The trigger is `flex items-center gap-1.5 font-mono text-xs
  text-[var(--color-text-dim)]` hovering to `text-[var(--color-text-secondary)]`,
  with an `h-3 w-3 transition-transform duration-150` chevron that gains
  `rotate-90` while open. The panel is `mt-3 p-4 rounded-md
  bg-[var(--color-surface-raised)] border border-[var(--color-border-subtle)]
  overflow-x-auto font-mono text-xs text-[var(--color-text-secondary)]
  leading-relaxed whitespace-pre-wrap` — it wraps rather than truncating, and
  scrolls only when a single unbreakable token is wider than the column.
- The row is deliberately the quietest thing on the page: dim mono micro-type at
  the very bottom. A reader who wants the markdown will look for it; one who does
  not should never notice it.
- No raw hex, no `!important`.

