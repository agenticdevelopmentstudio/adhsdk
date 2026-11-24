
### BrowserJarRecord

- **jar-id-is-store-id**: A jar record's `id` MUST be the identifier of its
  WebKit data store, so the row and the store cannot drift apart.
- **jar-id-defaults-new**: Constructing a `BrowserJarRecord` without an `id`
  MUST assign a fresh random UUID.
- **jar-label-default-empty**: Constructing a `BrowserJarRecord` without a
  `label` MUST give it an empty label.
- **jar-kinds-persisted-raw**: `Kind` MUST have exactly the cases `worktree` and
  `pane`, and their raw values (`worktree`, `pane`) MUST be what is stored in
  `browser_jars.kind`, where a `CHECK` constraint refuses any other value.
- **jar-equatable-by-fields**: Two records MUST compare equal when every field
  (`id`, `kind`, `repoID`, `worktreePath`, `paneNodeID`, `label`) is equal.
- **jar-pane-node-optional**: A caller MUST set `paneNodeID` for a `pane` jar and
  MUST leave it `nil` for a `worktree` jar; neither the type nor the table
  enforces this (the column is nullable and the initializer takes an optional).
- **jar-label-mutable**: `label` MUST be the only mutable field; it holds the
  last name the jar was shown under so a list can outlive the pane that named it.
- **jar-global-has-no-row**: The shared (global) jar MUST NOT have a row; the
  schema refuses a `global` kind and the global jar uses WebKit's default store.

### LiveBrowserPane

- **pane-standardized-path**: `LiveBrowserPane.standardizedPath(_:)` MUST return
  the standardized file-URL path of its input treated as a directory, and the
  pane at construction and the reconciler reading the layout MUST both use it,
  so a trailing slash never makes one worktree two jars.
- **pane-state-node-id**: `stateNodeID` MUST be `ownerNodeID` when set, otherwise
  `nodeID`.
- **pane-state-key-prefix**: `stateKeyPrefix(_:)` MUST return the prefix unchanged
  when `ownerNodeID` is `nil`, and otherwise the prefix followed by the pane's
  `nodeID` UUID string and a period.
- **pane-own-prefix**: `ownStateKeyPrefix` MUST equal `stateKeyPrefix` of the
  pane's own `statePrefix`.
- **pane-default-prefix**: A `LiveBrowserPane` constructed without a
  `statePrefix` MUST use the default browser state prefix of the composable-tabs
  registry, and without an `ownerNodeID` MUST have `nil` (a layout node itself).
- **pane-hashable**: `LiveBrowserPane` MUST be `Hashable` and `Sendable`, so sets
  of panes can be compared (the tests compare sets).

### Jar rows

- **insert-unique-worktree-jar**: `insertBrowserJar` MUST throw when a second
  worktree jar is inserted for the same repository and worktree path, because
  the unique index refuses it. A worktree jar for another path, or the same path
  in another project, MUST be accepted.
- **insert-unique-pane-jar**: `insertBrowserJar` MUST throw when a second jar is
  inserted for the same pane node id. Many pane jars MAY share one worktree path.
- **insert-loser-reads-winner**: The refusal of a duplicate is the contract that
  lets a caller that lost a race read the winner's row instead; the insert
  itself MUST NOT swallow or retry the error.
- **insert-stamps-created-at**: `insertBrowserJar` MUST store the current time
  as a Unix-epoch double in `created_at`.
- **find-worktree-jar**: `browserJar(worktreeOf:path:)` MUST return the record
  whose kind is `worktree`, repository id equals the argument and worktree path
  equals the argument exactly, or `nil` if none exists.
- **find-pane-jar**: `browserJar(pane:)` MUST return the record whose kind is
  `pane` and `pane_node_id` equals the argument, or `nil` if none exists.
- **relabel-by-id**: `updateBrowserJarLabel(id:label:)` MUST set the label of the
  row with that id; an id with no row changes nothing and does not throw.
- **delete-by-id**: `deleteBrowserJar(id:)` MUST delete the row with that id; an
  id with no row changes nothing and does not throw.
- **list-project-jars-order**: `browserJars(repoID:)` MUST return only that
  project's jars, worktree jars first and then pane jars, each group in
  creation order (the query orders by kind descending, then `created_at`).
- **list-all-jars-order**: `allBrowserJars()` MUST return every jar of every
  project in creation order.
- **creation-dates-by-id**: `browserJarCreationDates()` MUST return a map from
  jar id to its creation date, for the reconciler's grace period.
- **malformed-row-skipped**: NEEDS REVIEW: Not implemented in source. A row the code cannot read is dropped from the result with no throw and no log (a `browser_jars` row whose `id` or `repo_id` is not a UUID string, which the table does not forbid; a live-node row whose node id, repo id or worktree cannot be read); the schema's `NOT NULL` and `CHECK` constraints make a null path or unknown kind unreachable in `browser_jars`, so the open point is whether a silent skip is acceptable or a log line or error is wanted; evidence to settle it is how the reconciler treats a jar store whose row is skipped.
- **statement-failure-throws**: When a statement cannot be prepared, the
  operation MUST throw `ProjectDatabaseError.prepareFailed`, and when a step
  fails (a duplicate insert, a read error) it MUST throw
  `ProjectDatabaseError.executionFailed`, each carrying the SQLite error
  message.
- **operations-throw-on-failure**: Every operation here is `throws` and MUST
  surface the database's error to the caller rather than returning a default.

### Live pane discovery

- **live-layout-is-authority**: `liveBrowserPanes()` MUST treat `layout_nodes`
  (walked from each saved tab's root node) as the authority for which panes
  exist, not `pane_state`, so a fresh pane that has never written a state row is
  still listed.
- **live-leaves-only**: A layout leaf MUST count as a browser pane only while its
  `content_type` equals the engine's view id; a leaf whose content changed to
  something else MUST NOT count.
- **live-worktree-from-tab**: A pane's worktree MUST be its tab's
  `working_directory`, or the repository's own path (`git_repo.path`) when the
  tab's directory is null or empty, then standardized.
- **live-all-engines**: `liveBrowserPanes()` MUST list the panes of every
  `BrowserEngineKind`, since a Chrome pane holds a jar exactly as a Safari pane
  does, and MUST list a node id once even if more than one engine matches it.
- **live-nested-by-state-key**: `liveBrowserPanes(contentType:statePrefix:)` MUST
  also list a browser nested inside another pane, found by a `pane_state` key
  under a live node that begins with the state prefix followed by a UUID; the
  nested pane MUST carry the enclosing node as `ownerNodeID`, and a UUID equal
  to the owner's own id MUST NOT count as nested.
- **live-nested-needs-state**: A nested pane that has written no state row MUST
  NOT be listed; while it is open the registry's in-use set covers it.
- **live-ids-include-any-key-uuid**: `livePaneNodeIDs()` MUST return the node ids
  of the live browser panes plus every UUID found in any period-separated
  component of any `pane_state` key under a live node, of any pane type, because
  keeping a jar a little too long is cheap and deleting one a live pane holds
  signs the user out.
- **live-deduplicated**: A pane found as a leaf and again by a state key MUST be
  listed once.

### Upgrade

- **upgrade-pins-existing-panes-global**: `keepExistingBrowserPanesOnTheSharedJar()`
  MUST, for every live browser pane, write the storage-jar setting with the
  value `[global]` (a JSON-encoded array holding the global jar) into the
  pane's own state, in the shape the pane's settings sheet writes, so the sheet
  shows it as an override that the user can revert.
- **upgrade-keeps-existing-override**: A pane that already has a value for the
  storage-jar setting MUST keep it unchanged.
- **upgrade-index-merged**: The pane's index of overridden setting names (a JSON
  array of strings) MUST gain the storage-jar setting name only if it is absent,
  and MUST keep the names already present; running the upgrade twice MUST leave
  one entry (idempotent).
- **upgrade-fresh-database-noop**: On a database with no saved panes the
  upgrade MUST write nothing, so new panes keep the setting's default (a jar per
  pane).
- **upgrade-corrupt-index-reset**: An override index that is present but not a
  decodable JSON string array is treated as empty and rewritten to contain only
  the storage-jar name; the previous content is not preserved.
- **upgrade-keys-by-owner**: The state rows for a nested pane MUST be written under
  its `stateNodeID` (the owner) with its own key prefix, and for a layout-node
  pane under its own node id.

### Isolation

- **not-sendable-store**: The extension adds no isolation: `ProjectDatabase` is a
  `public final class` with no `Sendable` conformance and no actor isolation,
  so every call MUST be made from one thread or queue at a time by the caller.
  `BrowserJarRecord`, `BrowserJarRecord.Kind` and `LiveBrowserPane` are `Sendable`
  values.

