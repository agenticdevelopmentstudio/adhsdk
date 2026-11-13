---
id: ef7191ff-63a9-442a-b6d0-f8452a0aa1d6
title: "Document Navigation Tree"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Hierarchical document navigation tree with collapsible sections, adaptive desktop/mobile layouts, and active page tracking."
platforms:
  - typescript
  - web
tags:
  - navigation
  - tree
  - document-structure
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Document Navigation Tree

## Overview

A hierarchical navigation component that renders document structure as a tree with three distinct node types: collapsible sections (depth 0), navigable branches (depth 1+), and leaf pages with optional inline heading links. Adapts layout from a sticky desktop sidebar to a mobile slide-over drawer; tracks active page via route path and manages section expansion state independently of navigation. Used in document hosting contexts where readers need to orient themselves within a multi-section document tree and navigate quickly between pages and heading anchors.

## Behavioral Requirements

- **render-sections**: Component MUST render top-level section nodes as collapsible controls; clicking the chevron control MUST toggle that section's child-list visibility.
- **render-branches**: Component MUST render branch nodes (children with their own children) as navigable links that always appear when their parent section is expanded, without a second collapse control.
- **render-leaves**: Component MUST render leaf nodes (children with no further children) as navigable links.
- **render-headings**: Component MUST render a leaf node's inline page headings (from `node.headings` array) as a sub-list of links indented beneath that leaf.
- **track-active-page**: Component MUST accept an `activePath` prop and highlight the current page link (using `aria-current="page"` and visual styling) when `activePath` matches the node's `href`.
- **track-ancestor**: Component MUST apply ancestor styling to branch nodes whose `href` is a segment-boundary prefix of `activePath` — `activePath` MUST equal `node.href` followed by `/` and additional path segments, not merely start with the same characters (e.g., `/docs/guides` is an ancestor of `/docs/guides/getting-started`, but `/docs/guide` is not an ancestor of `/docs/guides/getting-started`).
- **support-heading-scrolling**: When a heading link's page is already active (`activePath` matches the leaf's `href`), clicking the heading MUST prevent default navigation and scroll the target heading element into view smoothly; when the page is not active, the link MUST navigate normally.
- **set-hash-on-heading-scroll**: When scrolling to a heading on the active page, component MUST update `window.history.replaceState` to set the URL hash without triggering navigation.
- **preserve-section-state-on-route-change**: Section expansion state MUST NOT change when `activePath` updates; it MUST only change when the toggle control is clicked.
- **manage-drawer-open-state**: Component MUST accept an `open` prop to control drawer visibility and MUST call `onClose` when the scrim backdrop is clicked or the close button is clicked.
- **initialize-expanded-sections**: On mount, component MUST set expanded sections to include all sections whose `href` matches `activePath` exactly, or is a segment-boundary prefix of it (`activePath` equals `node.href` followed by `/` and additional path segments — see **track-ancestor**).
- **order-children**: Component MUST render a node's children in a fixed order: leaf nodes first, then branch nodes; the order does NOT follow the input array order.
- **distinguish-link-component**: Component MUST accept a `LinkComponent` prop and use it for all navigation links; if omitted, MUST default to a plain `<a href>` element.
- **support-top-and-bottom-links**: Component MUST render fixed navigation rows (`topLinks` and `bottomLinks`) above and below the tree respectively, each behind its own divider rule.
- **render-headings-only-on-leaves**: Inline page headings MUST only render when present on leaf nodes; branch nodes MUST NOT render heading sub-lists.

## Appearance

- **Desktop layout**: Sticky aside, positioned at `top: var(--adh-header-height, 3.5rem)`, width `24rem` (expandable to `32rem` on wide/desktop viewports), right-aligned border, vertical overflow scrolls independently of the viewport
- **Mobile layout**: Slide-over drawer positioned at `left: 0`, width `18rem`, appearing on top of a scrim at 50% opacity black
- **Section labels**: Mono font, extra-small size, medium weight, uppercase, wide letter-spacing, always colored `var(--color-accent)` (no hover color change)
- **Branch and leaf links**: Small text size for branches/leaves, extra-small for headings; secondary text color by default, primary on hover; selected/ancestor links use semibold or medium weight
- **Selected indicator**: Vertical accent bar (1px width, `var(--color-accent)` color) at left edge of selected link
- **Indentation**: Links and headings use consistent padding-inline-start (0.875rem); nested lists add 0.875rem left margin per level
- **Dividers**: Border-top line (1px, `var(--color-border-subtle)` above fixed rows, `var(--color-border)` within tree levels
- **No text wrapping (desktop)**: Desktop nav prevents entries from wrapping onto a second line, with horizontal scrolling available for anything still too long; mobile allows wrapping

## States

| State | Appearance change |
|-------|-------------------|
| Section expanded | Chevron icon rotated 90°, section's child list visible |
| Section collapsed | Chevron icon at 0°, section's child list hidden |
| Link selected (exact match) | Semibold weight, primary text color, left accent bar |
| Link ancestor (prefix match) | Medium weight, primary text color, no accent bar |
| Link hover | Text color transitions to primary |
| Link default | Secondary text color |
| Heading link (not on page) | Text-xs, dim text color, appears as nested link |
| Heading link (on page, hover) | Text-xs, secondary text color, scrolls instead of navigating |
| Drawer open | Overlay and drawer visible, scrim blocks pointer events |
| Drawer closed | Drawer hidden, page content under aside fully visible |

## Accessibility

- **Navigation landmark**: Component renders a `<nav>` element (both desktop aside and mobile drawer use semantic nav)
- **Aria-current**: Selected links MUST carry `aria-current="page"` to announce to assistive technology
- **Section collapse button**: Collapse control MUST have `aria-expanded={true|false}` and an accessible label (`aria-label="Expand/Collapse [section name]"`)
- **Scrim not announced**: Scrim overlay carries `aria-hidden="true"` and is not focusable, ensuring screen readers do not announce it as a control
- **Drawer dismiss button**: Close button MUST have `aria-label` (e.g., "Close navigation")
- **Heading links nested under leaf**: Heading links appear in a nested list and inherit semantic structure from the leaf's `<li>` parent
- **Color not sole indicator**: Selected state uses both bold weight AND accent bar, not color alone
- **Contrast**: All text must meet WCAG AA contrast requirements against their backgrounds
- **Minimum touch target**: Section collapse button MUST be at least 44×44px (achieved via padding); links have 0.125rem vertical padding, totaling roughly 24-28px height, relying on spacing rather than individual link height for target size — below the 44px minimum on its own (see Compliance)

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| doc-nav-001 | render-sections | nodes with depth 0 | Sections render as collapsible divs with chevron button and aria-expanded attribute |
| doc-nav-002 | render-branches | node with children that have children | Branch links render without collapse control; appear when parent section is expanded |
| doc-nav-003 | render-leaves | node with children that have no further children | Leaf links render |
| doc-nav-004 | track-active-page | activePath="/docs/guides" with matching node href | Link styled with semibold, primary color, and left accent bar; aria-current="page" set |
| doc-nav-005 | track-ancestor | activePath="/docs/guides/getting-started" with ancestor node href="/docs/guides" | Ancestor link styled with medium weight and primary color; no accent bar |
| doc-nav-006 | support-heading-scrolling | activePath matches leaf, heading link clicked | preventDefault called, target element scrolled into view smoothly, history.replaceState called with hash |
| doc-nav-007 | support-heading-scrolling | activePath does NOT match leaf, heading link clicked | Link navigates normally (default behavior not prevented) |
| doc-nav-008 | preserve-section-state-on-route-change | Section expanded, activePath changed | Expanded state unchanged; only toggle control changes it |
| doc-nav-009 | manage-drawer-open-state | open=true, onClose callback provided | Drawer rendered and visible; clicking scrim calls onClose; clicking close button calls onClose |
| doc-nav-010 | initialize-expanded-sections | activePath="/section1/page" on mount | Sections whose `href` equals `activePath` exactly, or is a segment-boundary prefix of it (e.g. `href="/section1"`), are auto-expanded; other sections collapsed |
| doc-nav-011 | order-children | node with mixed leaves and branches in arbitrary input order | Leaves rendered first, then branches, regardless of input order |
| doc-nav-012 | distinguish-link-component | LinkComponent prop with custom link component provided | Custom component used for all links; defaulting to `<a href>` if omitted |
| doc-nav-013 | support-top-and-bottom-links | topLinks array with entries | Fixed rows render above tree with divider below them |
| doc-nav-014 | support-top-and-bottom-links | bottomLinks array with entries | Fixed rows render below tree with divider above them |
| doc-nav-015 | render-headings-only-on-leaves | branch node with headings array | Heading sub-list does NOT render; headings only on leaves |
| doc-nav-016 | render-headings | leaf node with a non-empty `headings` array | Heading sub-list renders below the leaf link, one entry per heading |

## Edge Cases

- **Empty children array**: If `node.children` is undefined or empty array, node is treated as a leaf; no branch or heading sub-list renders.
- **No headings**: If `node.headings` is undefined or empty array, NavHeadings returns null and no heading sub-list renders.
- **Heading element not found**: If `document.getElementById(heading.id)` returns null when scrolling, the scroll is skipped and hash is not set; link click event is still prevented.
- **Active path not in tree**: If `activePath` does not match any node `href`, no links styled as selected; section expansion state still initialized based on prefix matches.
- **Circular or malformed tree**: Component does not validate tree structure; if a node's href appears as a prefix of itself (invalid) or circular parent-child relationships exist, behavior is undefined; tree MUST be acyclic and well-formed by the host.
- **Very deep nesting**: No hard depth limit; rendering cost scales with tree size and React reconciliation, same as any other recursive component of this shape.
- **Drawer open at `lg` breakpoint**: Desktop nav is `hidden lg:block`; drawer renders at all breakpoints; both rendering simultaneously with `open=true` at `lg+` creates duplicate nav in DOM but only drawer is visible to user.
- **Route change during scroll**: If `activePath` changes while `element.scrollIntoView()` is in progress, the scroll completes but may scroll to an element that is no longer "on page" in the component's view (rare edge case, depends on timing).
- **Missing active page headings**: If `activePath` matches a node but the node has no `headings` array, component renders the leaf link without heading sub-list; this is correct behavior.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| nodes | HdvNavNode[] | required | Top-level sections of the document tree |
| activePath | string | required | Current route path; used to highlight active link and expand parent sections |
| topLinks | DocNavTopLink[] | [] | Fixed navigation rows above the tree |
| bottomLinks | DocNavTopLink[] | [] | Fixed navigation rows below the tree |
| LinkComponent | React component | DefaultDocLink (a href) | Router link component for all navigation links |
| open | boolean | false | Controls drawer visibility; only affects mobile drawer |
| onClose | () => void | undefined | Callback when drawer is dismissed by scrim or close button |
| title | ReactNode | "Navigation" | Drawer heading text |
| closeLabel | string | "Close navigation" | aria-label for drawer close button |
| className | string | undefined | CSS class applied to desktop aside only; not copied to drawer |
| ...rest | HTMLAttributes | {} | Standard HTML attributes (id, data-*, etc.) applied to desktop aside only |

## Deep Linking

Not applicable: this component is a navigation chrome, not a linkable destination. Page URLs are determined by the document tree nodes' `href` props, which the host provides.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `collapseSection` | Collapse {label} | Section toggle's `aria-label` when the section is expanded; the word "Collapse" is hardcoded in the source and has no config prop |
| `expandSection` | Expand {label} | Section toggle's `aria-label` when the section is collapsed; the word "Expand" is hardcoded in the source and has no config prop |
| `title` | Navigation | Drawer heading text (`title` prop default) |
| `closeLabel` | Close navigation | Drawer dismiss button's accessible name (`closeLabel` prop default) |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Chevron rotation uses a 150ms transition and heading scroll uses `behavior: "smooth"`, applied unconditionally. The source never checks `prefers-reduced-motion` anywhere, so neither the chevron rotation nor the heading scroll is ever made instant for a reader who has set that preference. |
| Increase Contrast | All text colors (secondary, primary, dim, accent) MUST meet WCAG AA 4.5:1 contrast against their backgrounds at all times; component relies on theme tokens to provide these values and does not override them. |
| Differentiate Without Color | Selected state uses BOTH bold weight and a vertical accent bar, not color alone; this is sufficient for color-blind users to distinguish selected from unselected. |

## Feature Flags

Not applicable: the component has no feature flags. All functionality is always enabled.

## Analytics

Not applicable: the component does not emit analytics events. Analytics instrumentation is the host's responsibility.

## Privacy

Not applicable: this component does not collect, store, or transmit user data. Navigation state (expanded sections, active path) exists only in React component memory and the browser URL.

## Logging

Not applicable: the component does not perform any logging.

## Platform Notes

- **React/Web**: Component is a React functional component using hooks (`useState`, `useCallback`) and JSX. Uses `lucide-react` for icons (ChevronRight, X) and `classnames` library (`cn` utility). Tailwind CSS for styling with custom CSS variables (`--adh-header-height`, `--color-*` tokens). Requires React 16.8+. Source file: `packages/web/packages/ui/src/blocks/doc-nav.tsx`.

- **SwiftUI**: Port to SwiftUI would start from `NavigationStack` or a custom tree view. Sections would be `DisclosureGroup` with a chevron icon and section label. Leaves and branches would use `NavigationLink`. Expanded sections would be local `@State`; `activePath` would be accepted as a plain value, not a binding, since the component only reads it and never writes back to it. Heading navigation would use `ScrollViewReader` to scroll to heading anchors on the current page. Drawer behavior maps to a sheet modifier with conditional presentation.

- **Compose**: Start from `LazyColumn` for the tree structure, since its own scrolling replaces a wrapping `Modifier.verticalScroll` rather than nesting inside one (a `LazyColumn` inside `verticalScroll` in the same axis crashes). Use `Row` with `IconButton` for section collapse control. `Text` for labels, `ClickableText` or custom `Modifier.clickable` for links. `mutableStateOf<Set<String>>` for expanded sections. Heading scrolling would use `LazyListState.animateScrollToItem()`. Drawer implemented as `ModalNavigationDrawer` (a side panel), not a bottom sheet.

- **AppKit / UIKit**: Use `NSOutlineView` (macOS) or implement a table view with custom cells (iOS). Section nodes render as parent rows with disclosure triangle. Branches and leaves as child rows. `NSOutlineView` itself manages expand/collapse state through its data source. For headings, implement an `NSViewController` or `UIViewController` hierarchy. Drawer on iOS uses `UISheetPresentationController`. Route tracking via URL observation or navigation controller delegate.

- **WinUI 3**: Use `TreeView` XAML control with `TreeViewNode` for sections, branches, and leaves. Section nodes have `Collapsed` and `Expanded` visual states; toggle chevron icon via binding to `IsExpanded`. Apply `PointerEntered` / `PointerExited` for hover styling. Heading sub-lists would use a second-level TreeView or an Expander control. For the drawer, use `NavigationView` or `SplitView` with conditional panel visibility; overlay with a `Grid` and semi-transparent `Border` for the scrim. Bind `activePath` to XAML with highlighting logic in code-behind or a converter. Heading navigation would scroll via `ScrollViewer.ChangeView()` or `FrameworkElement.StartBringIntoView()`, not a composition animation.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/doc-nav.tsx` | unverified |

## Design Decisions

- **Decision**: The drawer's `open` prop is controlled by the host, not managed internally by the component.
  **Rationale**: The "open" button lives in a separate header component outside this nav subtree. An uncontrolled drawer would leave that button silently dead after the drawer closed. Controlled state ensures the two stay in sync.
  **Approved**: pending

- **Decision**: Section expansion state is held above both renderings, in `DocNav`, rather than inside the tree component.
  **Rationale**: Desktop and mobile render the same tree description twice, as two separate React component instances. If expansion state lived inside the tree component, the desktop and mobile copies would diverge: the user opens a section on mobile, closes the drawer, and the section is now closed on mobile but still open on desktop. Holding `expanded` and `toggle` above both renderings keeps both instances in sync. A single-rendering host (desktop only) can omit this and let the tree own its own state internally.
  **Approved**: pending

- **Decision**: Expansion state does not auto-update on navigation; it is seeded from `activePath` once, on mount, only.
  **Rationale**: This preserves a reader's deliberate collapse choices as they navigate. Automatically closing a section they had opened would feel hostile.
  **Approved**: pending

- **Decision**: Heading sub-lists are part of the nav tree, not a separate anchoring feature.
  **Rationale**: Links to headings on the current page scroll instead of navigating; from any other page they navigate normally. This allows readers to jump within a long page without losing their place in the tree, and also keeps heading links shareable since the URL still carries the hash.
  **Approved**: pending

- **Decision**: The mobile drawer scrolls its own contents (`overflow-y-auto` on `nav`), not the page body.
  **Rationale**: Giving the drawer's own contents an independent scroll region means opening it doesn't require the page underneath to scroll for the nav to be usable. No explicit body-scroll lock is applied by this component, so the page behind the overlay can still scroll on its own.
  **Approved**: pending

- **Decision**: The desktop sidebar never wraps text, scrolling horizontally for anything still too long; the mobile drawer allows wrapping instead.
  **Rationale**: A row that wraps reads as two separate nav items, so the desktop column prevents it. Mobile deliberately omits this so long labels wrap onto a second line instead of requiring horizontal scroll, which is more natural on phone-sized screens.
  **Approved**: pending

- **Decision**: A node's children are ordered by type — leaves before branches — rather than following the host's input array order.
  **Rationale**: A reader scanning a section wants the section's own pages before its sub-directories. Without this reordering, the tree would read differently depending on how the host happened to sort the input array, reducing predictability.
  **Approved**: pending

- **Decision**: The selected link's indicator uses both bold weight and a left accent bar, not color alone.
  **Rationale**: This satisfies the requirement that status be distinguishable without relying on color alone (see **track-active-page** and the Differentiate Without Color accessibility option).
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

These statuses rest on: theme-token text colors used throughout for contrast; every interactive control (section toggle, links, drawer close button) being reachable and operable via tab and enter, with the scrim providing only a redundant pointer-only dismiss path alongside the keyboard-operable close button; semantic `<nav>`/`<ul>`/`<li>` markup with the host's `LinkComponent` (defaulting to `<a href>`) and `aria-expanded`/`aria-label` on the section toggle plus `aria-current="page"` on selected links; section-toggle buttons padded to 44×44px while link rows measure roughly 24-28px tall, short of that minimum (see Accessibility); and no `prefers-reduced-motion` handling anywhere in the source for the chevron rotation or heading scroll (see Accessibility Options). separation-of-concerns passes because `DocNavTree` (pure tree rendering and expansion state) and `DocNav` (drawer chrome and fixed top/bottom rows) are split apart, and neither pulls in the host's router beyond the injected `LinkComponent`. unit-test-coverage passes because `docNav.test.tsx` exercises both components across rendering, active/ancestor tracking, expansion persistence, heading scroll, drawer open/close, and accessibility.

## Data Model

- **HdvNavNode**: `{ label: string; href: string; headings?: HeadingEntry[]; children?: HdvNavNode[] }`. A node with a non-empty `children` array is a branch (or, at depth 0, a section); a node with no `children` is a leaf. There is no `kind` discriminator — depth and the presence of `children` are the only distinctions the tree draws.
- **HeadingEntry**: `{ id: string; text: string; depth: number }`. One heading extracted from the rendered document; `id` is the DOM id the component scrolls to and writes onto the URL hash.
- **DocNavTopLink**: `{ label: ReactNode; href: string }`. One fixed row for `topLinks` or `bottomLinks`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.2 | 2026-09-25 | Mike Fullerton | track-ancestor/initialize-expanded-sections corrected to segment-boundary prefix matching (T005/T010 fixed); moved Data Model after Compliance per template order. |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; moved styling out of render-sections into Appearance; added a Data Model section; reformatted Design Decisions to Decision/Rationale/Approved form; rebuilt the Compliance table with catalog check names, corrected categories, and removed unverified claims; fixed the Localization table's Default (en) column; removed platform-specific class tokens from Appearance; split test vector doc-nav-003 and added doc-nav-016 for render-headings; fixed the section-label appearance contradiction; removed the unverified deep-nesting performance claim; corrected the SwiftUI, Compose, AppKit/UIKit, and WinUI 3 platform notes |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
