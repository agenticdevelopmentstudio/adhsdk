
- **Wide / narrow + the branch reveal (2026-07-11).** The frame owns ONE measured row (`useContainerWidth`
  on the wrapper around the stacks, a `useLayoutEffect` + ResizeObserver so the first measurement lands
  pre-paint) and passes `containerW` down — so the mode decision and the covered stack's fit math read the
  same number and there is still a single disclosure controller. `const stripPx = disclosureStyle === "minimized" ? COLLAPSED_RAIL : COVERED_PEEK; const wideFloor = Math.max(minDetailPx(minDetailWidth) + stripPx, PHONE_FLOOR); const narrow = layoutMode === "narrow" || (layoutMode === "auto" && (phone || (containerW > 0 && containerW < wideFloor)))`; `usePhoneUserAgent` reads the UA AFTER mount
  (the server has none — branching the first render on it would be a hydration mismatch) and matches
  `/iPhone|iPod/` or Android + `Mobile`, so tablets/desktops (and iPadOS, which reports a desktop UA) are
  decided by width alone. **`NarrowStack`** renders a pane per level PLUS the detail, all
  `absolute inset-0`, positioned by `translateX`: the top pane at `0`, the ones behind it at `-30%`
  (the iOS parallax) + `inert`/`aria-hidden`, the ones ahead at `100%`. Panes are rendered for EVERY
  level (not just the current path) so one exists off-screen to slide IN, and a popped one slides OUT
  instead of unmounting; `anim` (the position the panes are rendered at) lags `top` by one
  `requestAnimationFrame`, because a pane that MOUNTS at its final position cannot transition — it must be
  painted off-screen once, then moved. Back = `levels[deepestSelected].onClear()` through `attemptExit`,
  the same path as the breadcrumb, so the unsaved guard is shared, not re-implemented.
  **The branch reveal** in `CoveredStack`: entering any covered (peeking) list sets `hoverId` to that
  list and `hoverAll` to true, which makes the group every ON-SCREEN list (from the leftmost visible
  one, not just the hovered list and its children) — revealed members take `railWidth` and chain from
  the leftmost on-screen list's own left edge, lifted to `z 50 + i` above the detail. Entering a
  DIFFERENT on-screen list once the group is open is a no-op (`inGroup(i)` is already true, so the
  handler returns before touching `hoverId`/`hoverAll`) — the group never re-roots or narrows.
  Closing is a
  property of the GROUP: `onPointerLeave` reads `e.relatedTarget`, finds its `[data-htd-col]` ancestor and
  KEEPS the branch open when that column is still in the group — a per-list leave handler would collapse
  the branch the moment the pointer crossed into one of its own children. The z-lift trails on close
  (`zLiftId`) so the wipe-shut happens over the detail rather than behind it.
- **Pins + the fit rules (2026-07-11; a since-parked `autoHide` layer is gone).** The frame OWNS the
  disclosure intent — `pins: Record<levelId, boolean>` — and passes it to whichever stack renders, so
  the two layouts share one contract and differ only in how a hidden list is DRAWN (a 32px peek vs an
  icon strip). Each stack resolves `pinned(i) = pins[id] ?? false` (no auto-hide fallback), then adds
  width pressure on top — pressure only ever ADDS a hide, so a pin shut is never disclosed.
  The `«`/`»` handlers read `e.metaKey || e.ctrlKey` to write EVERY level's pin instead of one.
  Phase 2 is quantised: `while (hidden < coverable && widthFrom(hidden) > containerW) { offshift +=
  widthOf(hidden); hidden++ }`, so the stack shifts by whole lists and a hidden column is `inert` +
  `aria-hidden` + `pointer-events-none` (mounted, so it slides back in on grow).
  `useInPlaceOnStructureChange(structureSignature(rendered))` returns true from a level-count /
  selection change until ~350ms after the LAST one and drops the `transition-[left,width]` classes
  across that window, so choosing a topic lands the detail in place — including the selection's
  trailing commits (levels registering, measured widths landing), which repaint geometry after the
  change itself. (The one-render version restored the transitions in a layout effect, which flushes
  BEFORE paint, so the browser animated the new geometry against the previous painted frame anyway.)
  Width-driven changes never touch that signature and keep animating. The detail's CONTENT swap is
  `DetailCrossfade`: a `getSnapshotBeforeUpdate` clone of the outgoing pane faded out over the
  incoming content (WAAPI, ~220ms), with per-surface module memory (`detailSwapMemory`) so the swap
  crossfades across the remount a route-param selection causes and a surface's first paint shows
  instantly.
- **React / Web (TypeScript).** Enclosing frame:
  `packages/web/packages/ui/src/blocks/hierarchical-topic-detail.tsx`
  (`HierarchicalTopicDetail`, props `levels: TopicLevel[]`, `disclosureStyle?: "covered" |
  "minimized"` (default `covered`), `layoutMode?: "auto" |
  "wide" | "narrow"` (default `auto`), `showBreadcrumb`,
  `rootLabel`, `trailingCrumbs`, `help`,
  `minDetailWidth`, `exitGuard: PaneExitGuard`, `manualCollapse`, `children`). It dispatches to a
  `NarrowStack` (full-width panes, `translateX` push/pop) once the wide layout is exhausted (the
  `wideFloor`: `minDetailWidth` + one strip, floored at `PHONE_FLOOR` (480px); this does NOT vary with
  the selection — an unselected frontier's own no-minimum landing is an exemption that belongs to the
  fit math, not to a lower narrow floor — or a phone UA), else a
  `CoveredStack` (absolute, overlapping, `COVERED_PEEK` = 32px) or a `MinimizedStack` (grid columns);
  in the wide styles it renders each level's `TopicRail` **and** the detail
  `<section key="__detail__">` as **flat sibling grid columns** (one
  `grid-template-columns` CSS var) — so the leaf has a stable slot (no remount) and ONE
  ResizeObserver drives the whole row. Rail primitive: `topic-detail.tsx` (`TopicRail`
  extracted from `TopicDetail`; the `New …` create affordance is a header `+` from `onNew` / `newLabel`
  / `newActive`; `railSlot: RailSlot` remains a `ReactNode | (collapsed) => ReactNode` render-prop for a
  standalone `TopicDetail`'s custom leading row — e.g. FocusedTopicDetail's PopupMenu — rendered only
  when supplied; optional `backSlot` for the drill-down Back; per-rail drag handle with
  snap-to-collapse/full; animated via `md:transition-[grid-template-columns]`).
  **Covered style:** a covered list's wrapper is `overflow-hidden` clipped to a 32px peek (its rows are
  always FULL, so only the leading icon shows — nothing of the label). Hovering it opens EVERY
  on-screen list — parents and children alike, not just the hovered list and what's below it — via an
  animated width **wipe** + a `left` chain (`CoveredStack` sets `hoverAll` true and chains members from
  the leftmost on-screen list's own left edge, not from the hovered list), lifted above
  the detail with a drop-shadow off the branch's trailing edge; the z-lift **lingers** (`zLiftId` trails
  `hoverId`) so the wipe-shut happens over the detail, and the close is
  decided from the leave event's `relatedTarget` so the branch survives the pointer walking into its own
  children — no portal copy, pointer-driven only (no focus reveal); entering a different on-screen list
  once the group is open never re-roots or narrows it. **Selection markers:** the shared `useSelectionConnectors` hook + `SelectionConnectorOverlay`
  SVG (`stroke-apt-gold`) draw the parent→child elbows, measured from the DOM via `data-htd-col` /
  `aria-current="true"` / `data-htd-label` / `data-htd-icon` and re-tracked on a short rAF loop across the
  cover slide (`selectionStyle="marker"` in the stack — root dash + connectors; `"bar"` for standalone).
  The frame owns: package-owned `onSelect`/`onClear` (re-click → `onClear`), the
  breadcrumb (derived from `levels`, up-nav via `onClear`, `help` + `trailingCrumbs`),
  the single-controller **off-screen drill-down** (`hidden` count from the observer:
  slide the leftmost lists to `0`-width + `inert`; never the frontier choosing-list while
  unselected), the **Back** button (leftmost-visible pane), and the **2-action
  Discard/Stay** `UnsavedChangesAlert` driven by `exitGuard` (`attemptExit`) — it never saves;
  `PaneExitGuard` exposes only `isDirty()`.
  **Unify-via-context.** Features publish their levels up rather than nesting their own
  frame: `workspace-chrome.tsx` (`useWorkspaceLevels` for a feature's topic levels via
  `useLayoutEffect`; `useWorkspaceListLevel` for a dismantled in-pane list, appended
  after the feature levels; `useWorkspaceExitGuard` publishing a **stable ref-backed
  proxy** so the per-render guard identity never loops the provider). The shell
  `WorkspaceShell.tsx` renders ONE merged `HierarchicalTopicDetail` over
  `[...shellLevels, ...chrome.levels, ...chrome.listLevel]`, with `help` =
  `helpFor(activeFeature)` wrapped in `HelpPopover`, and `exitGuard = chrome.exitGuard`.
  `ResourceTab` + the converted panes are **dual-mode**: inside the shell they publish
  levels and render only the leaf; standalone they render their own frame. The
  dismantled master/detail bridge is `useMasterDetailLevel` (publishes the list level +
  registers the editor's `guard` from `useMasterDetailForm`, whose `save()` returns a
  boolean). Reduce-motion support exists in the global `@adh-sdk/themes` accessibility CSS (zeroes
  transition durations), but is currently SUSPENDED for both hierarchical views by a standing product
  decision — see Design Decision **Reduced motion is suspended for this component**. Hub home is gated — verify shared UI on the
  **ui-showcase** (`hierarchical-topic-detail` demo) via Playwright at 375 / 768 / 1440,
  and the hub routes via `e2e/hierarchical-resource.spec.ts` (seeded mock-auth).
- **SwiftUI:** Implement the wide layout with `NavigationSplitView` (macOS/iPadOS) and the narrow layout with `NavigationStack`, each level's `selectedId` bound to `@State`/`@Binding`. Render each level's rows as a `List` section; the covered style maps to a custom overlay view (not a system `Popover`) for the branch reveal, with positioning computed from row frame geometry (`GeometryReader` / `.overlayPreferenceValue`). The detail pane is a conditional `NavigationLink` destination (wide) or the top of the `NavigationStack` (narrow). Unsaved-work guarding is a custom back guard, not `@Environment(\.scenePhase)` (which reports foreground/background, never navigation intent): gate the pop with `.interactiveDismissDisabled(isDirty)` and present a `.confirmationDialog` (Save / Discard / Cancel) before it proceeds. Deep links reconstruct the `selectedId` hierarchy from URL path components.
- **Compose:** Structure the wide layout as a `Row` of side-by-side `LazyColumn`s — one per level, flat siblings, not nested — plus the detail `Composable` in the same `Row`, mirroring the source's flat-sibling-grid contract. Covered disclosure uses `AnimatedVisibility` with scrim overlays; minimized uses fixed-width columns that shrink to an icon strip. Selection state lives in a shared ViewModel; navigate via `NavController` for the narrow (single-pane) layout. Unsaved-work guards hook into `BackHandler` (Compose's back-press API) with a custom confirmation dialog.
- **AppKit / UIKit:** On macOS (AppKit), use `NSSplitViewController` with N columns backed by `NSViewController` + `NSTableView` for each level; selecting a row updates the next column's data source (cascading binding). Covered style clips columns to a 32px peek using layer positioning and `NSClipView`; minimized uses proportional column sizing. On iOS (UIKit), use `UINavigationController` inside a custom container for each level (mirroring the narrow mode); a `UITableViewController` manages rows and selection. Unsaved guarding wraps navigation in `UIAlertController` confirm dialogs. Deep links are resolved via app delegate URL schemes / universal links, reconstructing the hierarchy and pushing each level's controller.
- **WinUI 3:** Build the wide layout as `Grid` columns — one column per level (each a `ListView`) plus the detail column — not a hierarchical `NavigationView` (which models one selected destination, not a row of sibling lists). Bind each row's selection to update the next level's `ItemsSource` via each `ListView`'s `SelectionChanged` (cascading data binding). Covered disclosure uses `Popup` overlays for branch reveals with Canvas-based 32px peeking on the outer container. Minimized style uses a horizontal `StackPanel` with column-width bindings. The detail pane is a separate content region in a `SplitView`. Navigate via each row's `SelectionChanged` handler — not a hyperlink command binding, which is for inline text links, not list-row navigation. Unsaved changes trigger a `ContentDialog` before navigation away. Deep links parse URL path segments and recursively select each level in the hierarchy using data-binding selection commands.

