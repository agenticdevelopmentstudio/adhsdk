
- **Decision**: The frame renders the lists + the detail as flat sibling grid columns, not nested panes.
  **Rationale**: The rendered row is visually identical, but ONE ResizeObserver sees the whole row (correct
  general→specific collapse) and the leaf keeps a stable slot (no remount/flash on list-count change) — this
  is what makes the single-controller drill-down possible (separation-of-concerns, simplicity).
  **Approved**: pending
- **Decision**: Every list is a level of the single stack; the deepest pane is only ever a detail.
  **Rationale**: Dismantling the in-pane master/detail (list+editor in one pane) into a published list level
  + a leaf editor keeps the model uniform and deep-linkable, and removes a whole class of nested-observer
  bugs (principle-of-least-astonishment, dry).
  **Approved**: pending
- **Decision**: A single full-width breadcrumb + help spans every list; the feature publishes its levels up
  through the `WorkspaceChrome` context (rather than nesting its own frame), so the shell renders ONE merged
  frame.
  **Rationale**: The entity selector is a first-class list, not a popup — this recipe supersedes the earlier
  popup-driven pattern for workspace routes.
  **Approved**: pending
- **Decision**: `onSelect`/`onClear` are pure navigation; the package decides which fires (re-click →
  `onClear`) and never auto-selects.
  **Rationale**: Consumers write no toggle/resume logic — unselection and no-auto-select hold uniformly
  (dry).
  **Approved**: pending
- **Decision**: Off-screen drilling isn't a special small-screen mode bolted on — it is the same
  single-controller fit math, so phones simply start with every list drilled off and the detail full-width,
  Back walking up.
  **Rationale**: The manual disclosure toggle coexists (a collapsed list counts as its icon width, then
  hides), so one fit controller serves both wide and phone layouts (optimize-for-change).
  **Approved**: pending
- **Decision**: The create affordance (`onNew`) rides right-justified in the titled header rather than as a
  reserved leading row, so the first topic sits directly under the header.
  **Rationale**: Row alignment across lists comes from the uniform titled header (same height + divider),
  not a reserved-when-empty slot — every consumer built the same "New …" button, so the component owns one
  `+` (dry, principle-of-least-astonishment). The `railSlot` render-prop stays for a standalone
  `TopicDetail`'s genuinely custom leading row (rendered only when supplied).
  **Approved**: pending
- **Decision**: The editor's button bar is the top of its leaf pane; its dirty/save state is published as a
  `PaneExitGuard`.
  **Rationale**: This lets the package raise the shared 2-action Discard/Stay `UnsavedChangesAlert` before any Back / up-nav discards work; the guard exposes only `isDirty()`, so saving remains the leaf editor's own affordance.
  **Approved**: pending
- **Decision**: A single keyed `site-config` store keeps help text out of components.
  **Rationale**: Consistent help copy across the platform (dry).
  **Approved**: pending
- **Decision**: The default `covered` style overlaps the lists like a stack of cards so the whole ancestry
  stays glanceable (a 32px peek) while the child + detail take the room — versus `minimized`, which slides
  parents fully off-screen.
  **Rationale**: Both share the one fit controller; covered is the better default on wide screens, and the
  same off-screen drill-down is the phone layout (principle-of-least-astonishment).
  **Approved**: pending
- **Decision**: A covered list shows only icons, so the pointer entering it lifts the ENTIRE real rail (full
  rows + header) above its neighbours rather than popping a per-row/per-header copy — one legible disclosure
  instead of many, disclosed only while the pointer is inside it.
  **Rationale**: Because it is the real rail (not a copy) there is no aria-current duplication and clicking
  a row behaves exactly like clicking it at rest (**own-unselection**), keeping the covered interaction predictable (simplicity,
  principle-of-least-astonishment). The reveal is pointer-driven only, never focus-driven — see
  **reveal-all-covered-lists-on-hover**.
  **Approved**: pending
- **Decision**: Hovering a peek opens EVERY on-screen list — parents and children alike, not just the
  hovered list's own children — rather than lifting just that one list, because the whole ancestry is
  the unit the user is actually reading.
  **Rationale**: An earlier version lifted only the hovered list, leaving its children covered behind it —
  telling you what you were choosing between but not what choosing would show you. A later version opened
  only the hovered list's own branch (itself and its children), which still left the hovered list's own
  PARENTS covered — walking the stack leftwards was a list-by-list re-rooting exercise. Opening every
  on-screen list from one hover answers the whole question at once, and makes the close condition a
  property of the GROUP (the pointer leaving every member), not of one list — walking from a list into
  another already-open member must not collapse what you are walking through
  (principle-of-least-astonishment), and entering a different on-screen list never re-roots or narrows
  the group. The branch itself no longer floats over the detail — see
  **push-detail-aside-on-reveal**, which supersedes the branch's original over-the-detail placement;
  only the covered peeks behind the branch stay overlapped.
  **Approved**: pending
- **Decision**: Once the wide layout's shrink sequence is exhausted — every list collapsed, the detail at
  its minimum, every collapsible list slid off-screen — the frame swaps the whole presentation for the
  platform-native one (`UINavigationController`) rather than shrinking the wide affordances further.
  **Rationale**: At that point peeks, cover toggles, the hover reveal and drag-resize are all pointer
  affordances spending room that no longer exists — and on a phone there is no pointer at all — so shrinking
  them further would be affordances masquerading as functionality. The same stack, selections,
  `onSelect`/`onClear` and unsaved guard continue underneath; nothing about a feature is phone-aware
  (native-controls, optimize-for-change). See **exhaust-wide-before-narrow** for the exact trigger.
  **Approved**: pending
- **Decision**: In the stack the selection is shown by a root dash + parent→child elbow connectors rather
  than a per-list left-bar.
  **Rationale**: The relationship between the selected rows reads at a glance across covered lists; the
  standalone primitive keeps its bar. The connector measurement and SVG are one shared
  `useSelectionConnectors` / `SelectionConnectorOverlay` used by both stacks (dry).
  **Approved**: pending
- **Decision**: `respect-reduced-motion` (the MUST requiring every animation to honor the user's
  reduce-motion preference) is currently SUSPENDED for both hierarchical views by a standing instruction from
  the block's owner — the `motion-reduce:` gates were removed so the two views cannot disagree once one flag
  picks between them.
  **Rationale**: This is a deliberate, temporary product decision (not a claim about anyone's OS
  configuration or a defect in the source); restore both views' gates together when the instruction is
  lifted. T18 and T51, which assert reduced-motion behavior, are marked suspended rather than deleted so
  they can be re-enabled the moment the gates return.
  **Approved**: pending

