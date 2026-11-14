
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| doc-toc-001 | accept-headings-array | `headings=[{id:"h1", text:"Introduction", depth:2}, {id:"h2", text:"Methods", depth:2}]` | Component renders a list with two anchor links. |
| doc-toc-002 | render-nothing-when-empty | `headings=[]` | Component returns null; no HTML is rendered. |
| doc-toc-003 | filter-headings | `headings=[{id:"h1", text:"Title", depth:1}, {id:"h2", text:"Appendix", depth:2}]`, `excludeIds=["h1"]` | Component renders only the "Appendix" link; "Title" is hidden. |
| doc-toc-004 | track-active-heading | User scrolls document so heading with id "h2" is in viewport. | Component's scrollspy hook identifies "h2" as active; link receives active styling. |
| doc-toc-020 | track-active-heading | Headings "h1" and "h2" (in that document order) both intersect the viewport band at once, reported by the observer in the order "h2", "h1". | "h1" is active, because it is first in document order. |
| doc-toc-021 | track-active-heading | "h2" is active, then a scroll leaves no heading intersecting the band. | "h2" stays active; no link loses its active styling. |
| doc-toc-005 | show-active-heading-styling | Heading with id "h1" is active. | Link renders with accent-colored left border, primary text color, medium font weight. |
| doc-toc-006 | show-inactive-heading-styling | Heading with id "h2" is inactive. | Link renders with transparent left border, dim text color, regular font weight. |
| doc-toc-007 | hover-inactive-headings | User hovers over an inactive heading link. | Text color changes to secondary. |
| doc-toc-008 | indent-by-depth | `headings=[{id:"h1", text:"Intro", depth:2}, {id:"h2", text:"Subsection", depth:3}]` | "Intro" link has 0.75 rem (12px) left padding; "Subsection" link has 1.5 rem (24px) left padding. |
| doc-toc-009 | scroll-page-on-click | User clicks a heading link with `href="#h2"`. | Page smooth-scrolls to the element with id "h2"; link's default behavior is prevented. |
| doc-toc-010 | use-custom-title | `title="Table of Contents"` | Component renders the custom title instead of the default "On this page". |
| doc-toc-011 | use-custom-title (default) | No `title` prop provided. | Component renders "On this page". |
| doc-toc-012 | transition-colors | User scrolls to change the active heading. | CSS transition effect smooths the color and border changes over approximately 150ms. |
| doc-toc-013 | respect-custom-classname | `className="my-custom-class"` | Component renders the aside with its default sticky positioning and layout intact, plus the custom class also applied. |
| doc-toc-014 | accept-html-attributes | `data-testid="toc"` | Component renders the aside with the `data-testid` attribute set to "toc". |
| doc-toc-015 | use-monospace-title | Component is rendered. | Title renders in font-mono, 10px, medium weight, uppercase, dim color. |
| doc-toc-016 | hide-below-xl | Screen width is 800px (below XL breakpoint, typically 1280px in Tailwind). | Component is not displayed (`display: none`); it stays in the DOM. |
| doc-toc-017 | be-sticky-positioned | User scrolls the document past the component's initial position. | Component remains visible and sticky, offset from the top by `--adh-header-height`. |
| doc-toc-018 | have-fixed-width | Component is rendered. | Component width is exactly 14 rem (224px); does not scale with content. |
| doc-toc-019 | use-custom-properties | Component is rendered in a themed environment providing `--color-accent`, `--color-text-primary`, etc. | All colors derive from CSS custom properties; component respects theme changes. |
| doc-toc-022 | render-nothing-when-empty, filter-headings | `headings=[{id:"h1", text:"Title", depth:1}]`, `excludeIds=["h1"]` | Component returns null; no HTML is rendered. |
| doc-toc-023 | scroll-page-on-click | User clicks a link whose `href` id matches no element in the document. | Default link behavior is prevented; no scroll occurs and no error is thrown. |
| doc-toc-024 | be-sticky-positioned | `--adh-header-height` is not defined. | The sticky offset from the top is 3.5rem. |
