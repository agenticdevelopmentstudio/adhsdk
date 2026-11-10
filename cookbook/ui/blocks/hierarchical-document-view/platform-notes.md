
- **SwiftUI**: Start from a `NavigationSplitView` with the nav tree as the sidebar
  and the document content as the detail column. Build the tree from nested
  `DisclosureGroup` views (top-level sections only expand/collapse; deeper levels
  render flat inside an open group, per the behavioral requirements) inside a
  `List`. Breadcrumbs: an `HStack` of `Button`/`Text` pairs separated by `/`
  `Text` views. Metadata: a `Grid` with two columns (label, value) mimicking the
  `dl`/`dt`/`dd` contract. Table of contents: a second `List` bound to the
  scrollspy's active id, shown or hidden with a plain `if`/`isPresented`
  condition rather than a disabled state. View source: a `DisclosureGroup`
  wrapping a monospaced, wrapping `Text`. On mobile widths, present the nav tree
  as a `.sheet` with `accessibilityAddTraits(.isModal)`, move focus into it on
  open with `@AccessibilityFocusState`, and dismiss on a `.keyboardShortcut(.escape)`
  action alongside the visible close button.
- **Compose**: Start from a `Row` with a collapsible nav `Column` (a `LazyColumn`
  of top-level sections, each an `ExpandableItem`-style composable driven by a
  single `remember { mutableStateOf(...) }` per section — only the top level
  toggles; deeper levels render flat while their section is expanded) and the
  document content in a second `Column`. Breadcrumbs: a `Row` of `Text`/
  `TextButton` separated by `/` `Text`. Metadata: a two-column `Row` per entry
  inside a `Column`, mirroring `dl`/`dt`/`dd`. Table of contents: a second
  `LazyColumn` bound to the scrollspy's active id, shown or hidden with
  conditional composition (`if (showToc) { ... }`), not a disabled modifier.
  View source: an expandable card holding a monospaced, wrapping `Text`. On
  mobile widths, present the nav tree in a `ModalNavigationDrawer` or
  `ModalBottomSheet`, request focus into it on open, and close it on back-press
  or a visible close action in addition to a scrim tap.
- **AppKit / UIKit**: On macOS, an `NSSplitViewController` with an
  `NSOutlineView` sidebar (top-level rows collapse/expand via
  `NSOutlineView` disclosure triangles; deeper rows stay flat once their
  parent is expanded) and the document content in the detail pane. On iOS, a
  `UISplitViewController` with a `UITableView` (grouped, disclosure-style
  sections) as the primary column. Breadcrumbs: a horizontal stack of buttons
  and separator labels. Metadata: a two-column `UIStackView`/`NSStackView`
  layout per entry. Table of contents: a second table/outline view bound to
  the scrollspy's active id, shown or hidden via `isHidden`, not `isEnabled`.
  View source: a disclosure-style cell revealing a monospaced, wrapping text
  view. On mobile widths, present the nav tree as a sheet or a
  `UISplitViewController` compact-mode overlay with `accessibilityViewIsModal`,
  move focus into it on open with `UIAccessibility.post(notification: .screenChanged, ...)`,
  and dismiss it on both a visible close control and the standard interactive
  dismiss gesture.
- **WinUI 3**: Start from a `NavigationView` with its pane holding the document
  structure and the document content region in the main area. Because only the
  top level collapses, render the pane as a stack of `Expander` controls — one
  per top-level section — each wrapping a flat, always-expanded `ItemsRepeater`
  for that section's deeper levels; a plain `TreeView` is the wrong control here
  because it puts an expander at every depth. Breadcrumbs: render as
  `StackPanel (Horizontal)` with `TextBlock` and `HyperlinkButton` elements
  separated by `/` `TextBlock`s. Metadata: use a `ListView` or custom
  `ItemsControl` with a two-column `DataTemplate` (label on left, value on
  right) mimicking the `dl`/`dt`/`dd` contract. Table of contents: render as a
  second pane bound to the scrollspy's active id, shown or hidden by binding
  `Visibility` (not `IsEnabled`, which leaves it visible but inert) to the
  viewport-width equivalent. View source: use an `Expander` control with a
  `TextBlock` child and `TextWrapping="Wrap"` for the source panel. Apply the
  ADH theme's color tokens as markup extensions in your app's resource
  dictionary, e.g. `{ThemeResource ColorTextPrimary}`, `{ThemeResource ColorAccent}`.
  Drawer for mobile-equivalent: use `NavigationView` with
  `PaneDisplayMode="LeftMinimal"` or `"LeftCompact"` triggered by window width.
  When the breadcrumbs already provide a route back to the parent document,
  set `IsBackButtonVisible="Collapsed"` so the two controls do not duplicate
  back-navigation; otherwise bind it to the last breadcrumb's route so the
  back button and the breadcrumb trail land on the same destination. Visual
  states: use `VisualStateManager` to control chevron rotation in collapse
  buttons via `RotateTransform`, and accent-bar appearance via conditional
  rendering. XAML pattern: compose the layout as a nested `Grid` with
  row/column definitions for the three-column structure, with a
  `ScrollViewer` wrapping the document content to handle long articles.
- **React/Web**: `packages/web/packages/ui/src/blocks/doc-breadcrumbs.tsx`, `doc-article.tsx`, `doc-metadata.tsx`, `doc-table-of-contents.tsx`, `view-source-disclosure.tsx`, `doc-nav.tsx`, `hierarchical-document-view.tsx`, `doc-link.tsx`, and the shared types in `doc-types.ts`. Exported from `@adh-sdk/ui/blocks`. `useScrollSpy` lives at `src/hooks/useScrollSpy.ts` and needed its own `./hooks/useScrollSpy` key in the package's `exports` map: unlike `./components/*` and `./blocks/*`, `./hooks/*` is not a wildcard, so a new hook is unreachable until its key exists. `doc-types.ts` is a `.ts` file, so the package's `./blocks/*` export wildcard (which resolves `.tsx` only) does not reach it; the `./blocks` barrel is its one public import path. No `transpilePackages` needed — a Next consumer resolves the package's `development` condition to raw `src/` under `next dev` and `import` to `dist/` in a production build. Tailwind classes are self-registered by `src/styles/components.css` (`@source "../blocks/**/*.{ts,tsx}"`). First consumer: an internal docs site's entry view and layout chrome. Implementation details: the two frames go in different files on purpose — `HierarchicalDocumentView` belongs in the host's layout and `DocPage` in its page; putting the nav in the page remounts the tree on every navigation. Demo: `ui-showcase` Topic `hierarchical-document-view`. Responsive: verify at 375 / 768 / 1440px that breadcrumbs wrap and metadata stays right-aligned.

