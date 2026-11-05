---
id: f1c3b5e7-9d2a-4f8c-a3c1-7e2f5b9c6d4a
title: Tree Rows
domain: adhsdk://recipes/tree-rows
type: ingredient
version: 1.2.2
status: review
language: en
created: 2026-09-22
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Hierarchical row display for nested parent-child relationships in tables
  and lists, exposing nesting depth and collapse-expand affordance.
platforms:
- typescript
- web
tags:
- tree
- hierarchy
- nested-rows
depends-on: []
related:
- adhsdk://recipes/disclosure
references: []
approved-by: ''
approved-date: ''
---

# Tree Rows

## Overview

Tree Rows exposes the nesting structure of hierarchical data within a flat row list. It exports a flatten algorithm that converts parent-child relationships into display order with depth metadata, a helper to compute ancestor expansion paths, and a visual row label component that renders indentation and a collapse-expand toggle. This allows tables, lists, and card grids to display hierarchy without becoming a new component — all existing column logic, sorting, selection, and keyboard behavior remain unchanged.

## Behavioral Requirements

- **flatten-parent-child-forest**: The flatten algorithm MUST accept a flat array of rows and output them in display order with depth and hierarchy metadata.
- **order-by-roots-first**: The algorithm MUST place root nodes (those without a parent in the input) at depth 0, in the order they appear in the input.
- **order-siblings-in-input-order**: The algorithm MUST order siblings of each parent in the input order unless a sort comparison function is provided.
- **sort-if-provided**: If a comparison function is provided in options, the algorithm MUST sort both roots and all sibling groups according to that function.
- **treat-orphans-as-roots**: A row whose `parentId()` result is not present in the input (filtered out, deleted, or missing) MUST be treated as a root at depth 0.
- **handle-self-parenting**: A row that is parented to itself MUST be treated as a root.
- **handle-cycles**: Rows that form a cycle (a→b→c→a) and are not reached by the depth-first descent MUST be surfaced at depth 0 in input order.
- **omit-collapsed-descendants**: When `expanded` is provided, the algorithm MUST withhold from the output any row whose nearest ancestor's id is not in `expanded`. The row is still walked (so cycle detection accounts for it) but is never pushed to the output until that ancestor is expanded.
- **surface-every-row-exactly-once**: Subject to **omit-collapsed-descendants** and to unique `id()` values across the input (see Edge Cases → Duplicate IDs), the output MUST contain every row from the input exactly once, in some order. The algorithm MUST NOT drop any row outside those two cases.
- **track-children-availability**: For each output row, a boolean `hasChildren` MUST indicate whether that row has any immediate children, regardless of expansion state.
- **compute-ancestor-path**: The `ancestorIds()` function MUST return the set of all ancestor IDs between a target ID and the root, given a list of rows and ID/parentId accessors.
- **halt-ancestor-search-at-cycle**: The `ancestorIds()` function MUST terminate if a parent is already in the result set (preventing infinite loops in malformed data).
- **halt-ancestor-search-at-missing-parent**: The `ancestorIds()` function MUST terminate if a parent ID is not present in the input.
- **render-label-span**: `TreeRowLabel` MUST render a `<span>` element containing indent, toggle (or spacer), and children.
- **indent-with-ems**: The label MUST apply inline padding based on depth: `depth * 1.25em`.
- **render-toggle-button-if-children**: If `hasChildren` is true, the label MUST render a button for toggling expansion.
- **render-spacer-if-no-children**: If `hasChildren` is false, the label MUST render a spacer element of identical width to the button (to align content).
- **show-toggle-icon**: The toggle button MUST display a chevron icon (ChevronRight from lucide-react, 14px).
- **rotate-icon-when-expanded**: When `expanded` is true, the chevron MUST be rotated 90 degrees.
- **call-on-toggle-on-click**: Clicking the toggle button MUST call the `onToggle()` callback without arguments.
- **set-aria-label-on-toggle**: The toggle button MUST have an `aria-label` attribute with the text "Expand {label}" or "Collapse {label}" depending on `expanded`.
- **set-aria-expanded-on-toggle**: The toggle button MUST have an `aria-expanded` attribute reflecting the current `expanded` boolean.
- **provide-title-on-toggle**: The toggle button MUST have a `title` attribute (tooltip) matching the `aria-label`.
- **use-flex-layout-in-label**: The label MUST use a flex layout with items centered on the cross axis and a small, consistent gap between the toggle/spacer and the content.
- **allow-shrinking-toggle**: The toggle/spacer element MUST NOT shrink when flex layout would otherwise compress it (web: `flex-shrink: 0`).
- **allow-content-truncation**: The label's outer `<span>` MUST allow its inline size to shrink below its content's natural width (an inline-size floor of 0) so a caller can truncate overflowing content with its own text-overflow styling.
- **accept-custom-classname**: `TreeRowLabel` MUST accept an optional `className` prop that is merged with the default classes.
- **accept-children-prop**: `TreeRowLabel` MUST render the `children` prop as content after the toggle/spacer.

## Appearance

- **Indent spacing**: `1.25em` per nesting level (computed inline as `depth * 1.25em` inline-start padding).
- **Toggle button**: No visible background at any state; the icon/text color and focus ring communicate interactivity (see the React/Web platform note for the exact classes).
- **Toggle size**: 14px chevron icon.
- **Toggle button padding**: `0.125rem` on all sides.
- **Toggle button corner radius**: platform-default rounded corner (`0.25rem` on web).
- **Toggle icon/text color**: muted-foreground token by default, default-foreground token on hover.
- **Toggle focus ring**: 2px ring in the accent (gold) token at 40% opacity, shown on focus-visible.
- **Toggle transition**: icon rotation is animated (see Accessibility Options → Reduce Motion).
- **Spacer size**: matches the toggle's box exactly (icon size + padding on all sides), so a leaf's content starts where a parent's does.
- **Layout**: flex row, items centered on the cross axis, with a small consistent gap between the toggle/spacer and the content.
- **Min-inline-size**: the label's outer element allows its inline size to shrink to zero so overflowing content can be truncated by the caller.

## States

| State | Appearance change |
|-------|------------------|
| Default (collapsed) | Chevron points right; toggle text reads "Expand {label}". |
| Expanded | Chevron rotated 90 degrees to point down; toggle text reads "Collapse {label}". |
| Leaf (no children) | Toggle button is absent; spacer element preserves layout. |
| Hover (toggle button) | Icon/text color changes from the muted-foreground token to the default-foreground token; no background appears. |
| Focus (toggle button) | Focus ring appears in the accent (gold) token at 40% opacity. |

## Accessibility

- **Role**: The toggle button is a native `<button>` with `type="button"`.
- **Aria-label**: Required. The button announces "Expand {label}" or "Collapse {label}" to screen readers.
- **Aria-expanded**: Required. The button sets `aria-expanded` to true or false reflecting the current state.
- **Title attribute**: Required. Provides tooltip text matching the aria-label for keyboard users and hover.
- **Label requirement**: Caller MUST pass a descriptive `label` prop (e.g., row title or data) so the toggle can announce which item is being toggled.
- **Leaf indication**: Leaves render a spacer instead of a disabled toggle, matching the toggle's footprint visually. The spacer is `aria-hidden="true"`, so screen reader users are not told about an empty, non-interactive placeholder — the visual alignment it provides is a sighted-only concern, not something assistive technology needs to perceive.
- **Focus visibility**: The button MUST have visible focus indication (ring on focus-visible).
- **Keyboard interaction**: The toggle button is a native button and MUST be keyboard accessible (Enter/Space to activate).
- **No role on label span**: The outer `<span>` is a layout container only and carries no `role` or semantic meaning. A caller embedding it in an ARIA tree/treegrid (`role="treegrid"`, `aria-level`, `aria-posinset`, `aria-setsize`) owns those attributes on its own row element — see Design Decisions → Tree-level ARIA semantics belong to the host.
- **Aria-hidden on spacer**: The spacer span MUST have `aria-hidden="true"` to prevent screen readers from announcing empty placeholder content.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tree-001 | flatten-parent-child-forest | Flat array of 3 rows: root A, root B, child of A | Output: A (depth 0), A's child (depth 1), B (depth 0). |
| tree-002 | order-by-roots-first, order-siblings-in-input-order | Array: [child of 'missing', root C, root A, child of A] | Output: child-of-missing (depth 0, orphan), C (depth 0), A (depth 0), child-of-A (depth 1). |
| tree-003 | treat-orphans-as-roots | Array: [row X with parentId='ghost-parent' (no row in the array has id='ghost-parent'), root Y with no parent] | X and Y both appear at depth 0; X is not dropped despite its missing parent. Output length is 2. |
| tree-004 | sort-if-provided | Array of 3 root rows and a compare function sorting by a custom field | All roots are sorted per the compare function. |
| tree-005 | handle-cycles | Array: [row A parented to B, row B parented to A, row C with no parent] | A and B are not reached by descent from C; they are surfaced at depth 0 in input order. |
| tree-006 | handle-self-parenting | Array: [row with id='X' and parentId='X', root Y] | Row X is treated as a root at depth 0. |
| tree-007 | surface-every-row-exactly-once | Array with mixed hierarchy and cycles, no `expanded` option, unique ids | Output length equals input length; each row appears once. |
| tree-008 | track-children-availability | Array: [root A with child B, root C with no children] | A has hasChildren=true; C has hasChildren=false; B has hasChildren=false. |
| tree-009 | compute-ancestor-path | Rows: A (root), B (parent A), C (parent B); focusId='C' | `ancestorIds()` returns {'A', 'B'}. |
| tree-010 | halt-ancestor-search-at-cycle | Rows forming cycle A→B→A; focusId='A' | `ancestorIds()` returns exactly {'A', 'B'} — the target id 'A' ends up included because the cycle loops back to it after one full traversal — and terminates rather than looping forever. |
| tree-011 | render-label-span | TreeRowLabel with depth=1, hasChildren=true, label='Item', children=<span>Content</span> | Renders a span with flex layout, padding-inline-start: 1.25em, a button, and the children span. |
| tree-012 | indent-with-ems | TreeRowLabel with depth=2 | Rendered span has style `paddingInlineStart: 2.5em`. |
| tree-013 | render-toggle-button-if-children | TreeRowLabel with hasChildren=true | Button element is present. |
| tree-014 | render-spacer-if-no-children | TreeRowLabel with hasChildren=false | Spacer span is present; button is absent. |
| tree-015 | show-toggle-icon | TreeRowLabel with hasChildren=true | ChevronRight icon (14px) is rendered inside the button. |
| tree-016 | rotate-icon-when-expanded | TreeRowLabel with expanded=true | Icon has `rotate-90` class. |
| tree-017 | call-on-toggle-on-click | TreeRowLabel with mock onToggle callback; click the button | onToggle() is called exactly once. |
| tree-018 | set-aria-label-on-toggle | TreeRowLabel with expanded=false, label='Folder' | Button aria-label is "Expand Folder". |
| tree-019 | set-aria-expanded-on-toggle | TreeRowLabel with expanded=true | Button aria-expanded is "true". |
| tree-020 | provide-title-on-toggle | TreeRowLabel with expanded=false, label='Folder' | Button title attribute is "Expand Folder". |
| tree-021 | accept-custom-classname | TreeRowLabel with className="custom-class" | Rendered span includes "custom-class" in its className. |
| tree-022 | accept-children-prop | TreeRowLabel with children=<strong>Bold text</strong> | Strong element is rendered after the toggle/spacer. |
| tree-023 | omit-collapsed-descendants | Rows: A (root), B (parent A), C (parent B); expanded = {A} | Output: A (depth 0, hasChildren=true), B (depth 1, hasChildren=true). C is withheld — it is reached during the walk but never pushed to the output because B is not in `expanded`. |
| tree-024 | halt-ancestor-search-at-missing-parent | Rows: A (root, no parent), B (parentId='missing', no row has id='missing'); focusId='B' | `ancestorIds()` returns {'missing'} — the missing parent id is itself added to the result before the search halts, since the next lookup finds no matching row. |
| tree-025 | use-flex-layout-in-label | TreeRowLabel with any valid props | The outer `<span>` has computed `display: flex`, `align-items: center`, and a small consistent `gap` between the toggle/spacer and the children content. |
| tree-026 | allow-shrinking-toggle | TreeRowLabel with hasChildren=true | The toggle `<button>` has computed `flex-shrink: 0`. |
| tree-027 | allow-content-truncation | TreeRowLabel with hasChildren=true or false | The outer `<span>` has computed `min-width: 0`, letting it shrink below its content's natural width. |
| tree-028 | flatten-parent-child-forest | `flattenTree([], options)` — empty rows array | Returns `[]`. |
| tree-029 | treat-orphans-as-roots | Single row whose `parentId()` returns `null` | Row is treated as a root at depth 0, the same as a missing or undefined parentId. |

## Edge Cases

- **Empty input**: If the input rows array is empty, `flattenTree()` returns an empty array.
- **Single root, no children**: Input is a single row with no parent; output is a single TreeRow at depth 0 with hasChildren=false.
- **Null or undefined parentId**: If `parentId()` returns null or undefined for any row, that row is treated as a root.
- **Duplicate IDs**: `id()` MUST return a unique value per row — this is a caller precondition, not something `flattenTree()` validates. Internally, the depth-first walk tracks visited rows by id in a `reached` set: whichever row bearing a given id is walked first is added to the output, and any later row sharing that id returns early (`reached.has(key)`) and is silently omitted. It does not become an orphan — it is dropped. Do not rely on a duplicate-id row appearing anywhere in the output.
- **Very deep nesting (10+ levels)**: The algorithm MUST handle arbitrary nesting depth. At 10 levels, indent is 12.5em; at 20 levels, 25em. No depth limit is enforced.
- **Large input (1000+ rows)**: The algorithm uses a single O(n) pass to build the index and a single depth-first walk, which is linear in row count. When a `compare` function is provided, sorting each sibling group (and the roots) adds up to O(n log n) on top of that linear walk.
- **All rows are orphans**: If all rows have missing parents, all are treated as roots and rendered at depth 0.
- **Mixed cycles and valid hierarchy**: Rows in valid chains are reachable and rendered in depth-first order. Rows in cycles are detected at the end and surfaced at depth 0.
- **Expansion set does not match input**: If `expanded` Set contains IDs not in the input, they are ignored. If it omits IDs that are in the input, those rows are treated as collapsed (see **omit-collapsed-descendants**).
- **Label prop is empty string**: `TreeRowLabel` MUST still render; aria-label becomes "Expand " or "Collapse " (with trailing space).
- **TreeRowLabel with depth=0**: Indent is 0 (no padding); toggle and content align to the left edge.
- **TreeRowLabel with negative depth**: `depth` MUST be supplied by the caller as a non-negative integer — this is a precondition, not a validated input. `flattenTree()` itself never produces a negative depth, but a caller invoking `TreeRowLabel` directly with a negative value gets a negative `padding-inline-start`, which is out of contract, not handled.

## Configuration

### `flattenTree(rows, options)`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `id` | `(row: T) => string` | Required | Accessor returning a unique string ID for each row. `flattenTree()` does not validate uniqueness — see Edge Cases → Duplicate IDs for the behavior when this precondition is violated. |
| `parentId` | `(row: T) => string \| null \| undefined` | Required | Accessor returning the ID of the row's parent, or null/undefined for a root. |
| `expanded` | `ReadonlySet<string>` | Omit (expand all) | Set of parent row IDs whose children SHOULD be shown. If omitted, all rows are expanded. See **omit-collapsed-descendants**. |
| `compare` | `(a: T, b: T) => number` | Omit (input order) | Comparison function to sort roots and sibling groups. If omitted, input order is preserved. |

**Output — `TreeRow<T>`**

| Field | Type | Description |
|-------|------|-------------|
| `row` | `T` | The caller's own row object, unchanged. |
| `depth` | `number` | 0 for a root; +1 per ancestor. |
| `hasChildren` | `boolean` | Whether the row has any immediate children at all, regardless of expansion state. |

### `ancestorIds(rows, focusId, { id, parentId })`

| Parameter | Type | Description |
|-----------|------|-------------|
| `rows` | `readonly T[]` | The full row set to search. |
| `focusId` | `string` | The row whose ancestors are being computed. |
| `id`, `parentId` | accessors | The same accessors passed to `flattenTree`. |

Returns `Set<string>` — see **compute-ancestor-path**, **halt-ancestor-search-at-cycle**, and **halt-ancestor-search-at-missing-parent**.

### `TreeRowLabel` props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `depth` | `number` | Required | Nesting level. MUST be a non-negative integer — not validated; see Edge Cases → TreeRowLabel with negative depth. |
| `hasChildren` | `boolean` | Required | Whether to render the toggle button (`true`) or the spacer (`false`). |
| `expanded` | `boolean` | Required | Current expand/collapse state; drives the chevron rotation and the aria-label/title text. |
| `onToggle` | `() => void` | Required | Called with no arguments when the toggle button is clicked. |
| `label` | `string` | Required | Names the row for the toggle's accessible name ("Expand {label}" / "Collapse {label}"). |
| `className` | `string` | Omit | Merged with the component's default classes. |
| `children` | `React.ReactNode` | Required | Rendered after the toggle/spacer. |

## Deep Linking

Not applicable: Tree Rows is a UI primitive for table and list display, not a navigable destination.

## Localization

"Not applicable" is incorrect: the toggle's accessible name and tooltip are built from the caller's `label` prop plus the hardcoded English words `"Expand"` and `"Collapse"` (see **set-aria-label-on-toggle** and **provide-title-on-toggle**). Those two words are not externalized into a resource file or otherwise made overridable — every locale sees the same English text regardless of the language of the caller's `label` value. This fails the **string-externalization** and **no-hardcoded-strings** compliance checks (see Compliance). `padding-inline-start` is used for the indent, which is direction-aware and needs no separate RTL handling.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | The component applies `transition-transform` to the chevron icon rotation but never queries `prefers-reduced-motion`; the animation plays regardless of the user's motion preference. |
| Increase Contrast | Focus ring color and hover state text color use the `apt-gold` and `apt-text` design tokens; see the open question on contrast. |
| Differentiate Without Color | Toggle state is communicated by aria-expanded, title, and icon rotation (visual), not by color alone. Focus is indicated by a ring, not color. |

- **contrast**: NEEDS REVIEW: Not implemented in source. Focus ring and hover-state text colors are set from the `apt-gold` and `apt-text` design tokens (`tree-rows.tsx`); their resolved contrast ratios cannot be verified from this file — confirm they meet the required WCAG contrast ratios.

## Feature Flags

Not applicable: Tree Rows is a low-level component library export with no runtime feature flags.

## Analytics

Not applicable: Tree Rows is a UI primitive with no built-in event tracking.

## Privacy

Not applicable: Tree Rows does not collect, store, or transmit any user data.

## Logging

Not applicable: Tree Rows does not emit logs.

## Platform Notes

Each bullet below assumes this recipe's flatten-plus-label approach: hierarchy layered onto an *existing* flat table, list, or card grid (see Overview). For a standalone tree browser that owns its own selection, keyboard navigation, and virtualization, prefer the platform's native tree control instead — see Design Decisions → Native tree controls vs. this recipe.

- **React/Web**: Source is `packages/web/packages/ui/src/components/tree-rows.tsx`. Exports `flattenTree()`, `ancestorIds()`, `TreeRowLabel` component, and the `TreeRow<T>` interface. `TreeRowLabel`'s use of `React.ReactNode` and `React.ReactElement` are ordinary TypeScript/React types, not hooks — the component calls no React hooks. Layout is Tailwind (`flex items-center gap-1 min-w-0` on the outer span); the toggle is `shrink-0 rounded p-0.5 text-apt-text-muted outline-none hover:text-apt-text focus-visible:ring-2 focus-visible:ring-apt-gold/40`, and its icon uses `transition-transform` plus a conditional `rotate-90`, from Lucide React's `ChevronRight`.

- **SwiftUI**: A tree-flattening algorithm is feasible in Swift using the same depth-first descent with cycle detection. The visual affordance would use an `HStack` for layout, a `Button` for the toggle, a fixed-size placeholder view for the leaf case, and an `Image` for the chevron. Convey the expanded state to VoiceOver with `.accessibilityAddTraits(.isButton)` plus `.accessibilityValue(expanded ? "Expanded" : "Collapsed")` rather than relying on the label alone, and read `@Environment(\.accessibilityReduceMotion)` to decide whether `.rotationEffect()` animates.

- **Compose (Kotlin/Android)**: A tree-flattening algorithm is feasible as a standalone utility function. The row label would use a `Row` for layout with `Modifier.padding()` for indent, an `IconButton` for the toggle, a fixed-size `Spacer` for the leaf placeholder, and an `Icon` for the chevron. Accessibility is set via `Modifier.semantics { role = Role.Button }` and `contentDescription` on the button — there is no Compose equivalent of `LocalDensity` for contrast or motion. To decide whether the chevron's rotation should animate, read the system's `Settings.Global.ANIMATOR_DURATION_SCALE` / `TRANSITION_ANIMATION_SCALE` (typically surfaced through a `ContentResolver`-backed `CompositionLocal`).

- **AppKit / UIKit**: A tree-flattening algorithm is feasible as a pure Swift function. The row label would be a `UIView`/`NSView` subclass with a `UIButton`/`NSButton` for the toggle, a fixed-size `UIView`/`NSView` for the leaf placeholder, and a `UIImageView`/`NSImageView` for the chevron. Layout uses Auto Layout (`NSLayoutConstraint`), not SwiftUI. Query `UIAccessibility.isReduceMotionEnabled` (`NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` on macOS) to conditionally disable the chevron's rotation animation.

- **WinUI 3**: A tree-flattening algorithm is feasible in C#. The row label would use a horizontal `StackPanel` for layout, a `Button` for the toggle, a `Border` or empty `Grid` sized to match the button for the leaf placeholder, and an icon glyph (e.g., Segoe MDL2 `ChevronRight`) for the chevron. Indentation is applied via `Margin` on the `StackPanel`. Expose the toggle through UI Automation's `ExpandCollapse` pattern (`IExpandCollapseProvider`) rather than binding to `IsPressed`, and set the accessible name with `AutomationProperties.Name` — not `AutomationProperties.AutomationId`, which is an identifier, not a name. Rotate the chevron with a `RotateTransform` in a storyboard, and respect `UISettings.AnimationsEnabled` to conditionally disable it.

## Design Decisions

**Decision**: Orphans are surfaced as roots rather than dropped.
**Rationale**: This prioritizes visibility over strict hierarchy correctness — a user's view will not silently lose rows due to missing parents. The tradeoff is that inconsistent parentId mappings become visible in the UI.
**Approved**: pending

**Decision**: Cycles are detected only after a full depth-first descent, and unreached rows are surfaced at depth 0 in input order.
**Rationale**: This ensures no row is lost and all rows are visited exactly once. The cost is O(n) space for the `reached` set and a final O(n) scan.
**Approved**: pending

**Decision**: Leaves render a spacer element (not a disabled toggle) to preserve layout alignment across parent and leaf rows.
**Rationale**: A disabled button would imply interactivity (and accessibility) that does not exist; a spacer is semantic and silent.
**Approved**: pending

**Decision**: The toggle uses a ChevronRight glyph (rotated 90° when expanded) instead of a separate DownChevron glyph.
**Rationale**: This is consistent with the Disclosure component in the same design system (see `related`) and reduces icon count.
**Approved**: pending

**Decision**: Indent is set to `1.25em` per nesting level.
**Rationale**: Visually distinct at moderate nesting depth (up to 5–6 levels) without consuming excessive horizontal space — at 5 levels, `6.25em` of inline-start padding is typical for desktop layouts.
**Approved**: pending

**Decision**: The toggle button has no visible background or border by default, appearing as a muted-foreground chevron; hover and focus states are subtle (foreground color change and focus ring).
**Rationale**: This keeps the row visually clean and focuses attention on the content, not the toggle itself.
**Approved**: pending

**Decision**: Ports and callers building a standalone tree browser — one that owns its own selection, keyboard navigation, and virtualization — should reach for the platform's native tree control instead of this recipe: SwiftUI `OutlineGroup`/`DisclosureGroup`, AppKit `NSOutlineView`, WinUI 3 `TreeView`/`TreeViewItem`, or web `role="treegrid"`/`aria-level`. `flattenTree` and `TreeRowLabel` exist for the opposite case: hierarchy layered onto an *existing* flat table, list, or card grid whose column logic, sorting, resizing, selection, and keyboard behavior must keep working unchanged (see Overview).
**Rationale**: A native tree control owns its own row rendering and interaction model; grafting it onto an existing table would mean re-deriving that table's behavior inside the tree control instead of reusing it.
**Approved**: pending

**Decision**: `TreeRowLabel` and `flattenTree` do not set `role="treegrid"`, `aria-level`, `aria-posinset`, or `aria-setsize`.
**Rationale**: The component intentionally does not become a `<TreeTable>` (see Overview) — the caller's own table/list row owns the outer semantic element, so tree-level ARIA attributes belong there, not in this inner label.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | failed | Accessibility |
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | failed | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | passed | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Statuses rest on `tree-rows.tsx` itself: the native `<button>` with `aria-label`/`aria-expanded`/`title` and its default keyboard behavior support the passed screen-reader, keyboard, and semantic-markup checks; the 14px icon plus `0.125rem` padding falls short of standard touch-target minimums and the chevron's `transition-transform` runs unconditionally regardless of `prefers-reduced-motion` (both also tracked under Accessibility Options above); contrast for the `apt-gold`/`apt-text` tokens can't be verified from this file (see the open question on contrast); and the hardcoded `Expand`/`Collapse` English strings fail string-externalization and no-hardcoded-strings, while the logical `paddingInlineStart` property and the unfiltered pass-through of the caller's `label` string pass rtl-layout-support and unicode-support. `separation-of-concerns` passes because the file is deliberately split between the pure, React-free `flattenTree`/`ancestorIds` and the presentational `TreeRowLabel`, and `unit-test-coverage` passes on `treeRows.test.tsx`'s direct exercise of both.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.2 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.2.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case; fix an RFC 2119 inversion and add duplicate-id/negative-depth preconditions; add an omit-collapsed-descendants requirement and test vectors; reformat Design Decisions and add two new entries; rewrite Compliance as a table; correct Appearance/Platform Notes values and move Tailwind specifics off Requirements/Appearance; split Configuration per export; fix the tree-003 and tree-010 vectors and add missing coverage; link the Disclosure recipe in related. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Revise Reduce Motion and Increase Contrast markers; clarify token requirements and motion animation behavior. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from tree-rows.tsx source. |
