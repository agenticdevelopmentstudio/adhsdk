
### ProjectShelfPanel

- **panel-cases**: `ProjectShelfPanel` MUST have exactly the cases `browser` and
  `activeProjects`, `CaseIterable`.
- **panel-raw-values-persisted**: The raw values (`browser`, `activeProjects`) are
  what is persisted, so a new case MUST be added and an existing one MUST NOT
  be renamed.
- **panel-codable**: `ProjectShelfPanel` MUST be `Codable` and `Sendable`.
- **panel-title**: `title` MUST be `Project Browser` for `browser` and
  `Active Projects` for `activeProjects`; it is the button tooltip and the key
  command title.
- **panel-symbol**: `symbol` MUST be the SF Symbol `folder` for `browser` and
  `square.stack.3d.up` for `activeProjects`.
- **panel-filter-placeholder**: The filter placeholder MUST be `Filter Projects`
  for `browser` and `Filter Active Projects` for `activeProjects`; it is shown in
  the bottom filter field while that panel is up. It is internal to the
  module, while `title` and `symbol` are public.
- **panel-more-will-join**: The enumeration is documented as open to additions;
  a consumer MUST NOT assume two cases are the full set.

### ProjectWindowState

- **state-fields**: `ProjectWindowState` MUST carry `id` (`UUID`), `activeRepoIDs`
  (`[UUID]`), `selectedRepoID` (`UUID?`) and `panel`, and MUST be `Codable`,
  `Sendable` and `Equatable`.
- **state-defaults**: Constructing `ProjectWindowState` with no arguments MUST
  produce a fresh random `id`, an empty `activeRepoIDs`, a `nil` `selectedRepoID`
  and `panel` equal to `browser`.
- **state-has-no-filter**: The persisted state MUST NOT contain `filterText`.

### ProjectWindowGroup

- **group-main-actor**: `ProjectWindowGroup` MUST be isolated to the main actor.
- **group-observable**: It MUST be a `final` class, an `ObservableObject` and
  `Identifiable`, with `id` as its identity.
- **group-init-from-state**: Constructing it from a `ProjectWindowState` MUST copy
  `id`, `activeRepoIDs`, `selectedRepoID` and `panel` from that state; with no
  argument it MUST use a default `ProjectWindowState`.
- **group-init-empty-filter**: A newly constructed group MUST have an empty
  `filterText`.
- **group-state-snapshot**: `state` MUST return a `ProjectWindowState` holding the
  group's current `id`, `activeRepoIDs`, `selectedRepoID` and `panel`.
- **group-filter-not-persisted**: `filterText` MUST NOT be part of `state`,
  because a filter is a moment's question and returning to a list already
  narrowed by yesterday's filter reads as projects having gone missing.
- **group-filter-per-panel**: `filterText` MUST be keyed by panel, so each
  panel's field keeps its own text.
- **group-published**: `activeRepoIDs`, `selectedRepoID`, `panel` and `filterText`
  MUST be published properties.
- **group-mutation-access**: `activeRepoIDs` and `selectedRepoID` MUST be
  settable only inside the module (`internal(set)`), while `panel` and
  `filterText` are publicly settable; `activate(_:)`, `deactivate(_:)` and
  `select(_:)` MUST be internal to the module, so only the window manager
  changes the list and selection.
- **group-contains**: `contains(_:)` MUST return `true` exactly when the id is in
  `activeRepoIDs`.
- **activate-appends-after-selected**: `activate(_:)` MUST insert the id
  immediately after the selected project when a selected id exists and is in
  the list, so a project opened from the browser lands next to the one the user
  was working in.
- **activate-appends-at-end**: `activate(_:)` MUST append the id to the end when
  no project is selected or the selected id is not in the list.
- **activate-idempotent**: `activate(_:)` MUST do nothing when the id is already
  in the list (no reorder, no publish).
- **activate-keeps-selection**: `activate(_:)` MUST NOT change `selectedRepoID`.
- **deactivate-removes**: `deactivate(_:)` MUST remove the id from
  `activeRepoIDs` when present.
- **deactivate-absent-noop**: `deactivate(_:)` of an id not in the list MUST
  change nothing and MUST return the current `selectedRepoID`.
- **deactivate-not-selected**: Deactivating a project that is not the selected one
  MUST return the current `selectedRepoID`.
- **deactivate-selected-next**: Deactivating the selected project MUST return the
  project that followed it in the list, or, if it was last, the one before it.
- **deactivate-selected-none**: Deactivating the selected project when no other
  remains MUST return `nil`.
- **deactivate-leaves-selection-to-caller**: `deactivate(_:)` MUST NOT itself change
  `selectedRepoID`; the caller applies the returned id (it is
  `@discardableResult`).
- **select-changes-only-on-difference**: `select(_:)` MUST assign `selectedRepoID`
  only when the new value differs, so equal selections publish nothing.
- **select-accepts-nil**: `select(nil)` MUST clear the selection.
- **selection-not-validated**: The group MUST NOT itself check that `selectedRepoID` is in `activeRepoIDs`: neither the initializer, `select(_:)` nor `activate(_:)` validates it, and the initializer neither de-duplicates nor validates the persisted list. The consistency is the caller's: the window manager selects only a project it has a window for, applies the id `deactivate(_:)` returns, and on restore moves a persisted selection that is not in the filtered active list to the first active project.
