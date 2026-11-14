
Derived from `BrowserJarTests.swift` in the macOS test target where a test
exists (its name is in the Requirements column); a row with no test named is
derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| jars-001 | insert-unique-worktree-jar, insert-unique-pane-jar, jar-global-has-no-row (`testTheSchemaRefusesDuplicateJarsAndUnknownKinds`) | Insert worktree jar for repo R at `/a`, then again | Second insert throws; a worktree jar at `/b`, and one at `/a` in another repo, are accepted |
| jars-002 | insert-unique-pane-jar (same test) | Insert pane jar for node N, then again for N, then a pane jar for a new node at the same path | Second throws; third succeeds |
| jars-003 | jar-global-has-no-row, jar-kinds-persisted-raw (same test) | Execute an `INSERT` with kind `global` | Throws (the `CHECK` constraint) |
| jars-004 | find-worktree-jar, find-pane-jar, relabel-by-id, delete-by-id, list-project-jars-order, list-all-jars-order (`testRecordsRoundTripAndRename`) | Insert a pane jar then a worktree jar in repo R; list, find, relabel the pane jar to `Docs`, delete it | `browserJars` returns `[worktree, pane]`; finds equal the records; label reads `Docs`; after delete `browserJar(pane:)` is `nil` and `allBrowserJars` is `[worktree]` |
| jars-005 | live-layout-is-authority, live-leaves-only, live-worktree-from-tab, live-ids-include-any-key-uuid (`testLiveBrowserPanesFollowTheSavedLayout`) | Tab with working directory W holds a split of a browser leaf and an editor leaf; second tab with none holds a browser leaf | Live panes are the two browser leaves, with W and the repository path (both standardized); `livePaneNodeIDs` is those two ids |
| jars-006 | upgrade-pins-existing-panes-global, upgrade-index-merged (`testAnUpgradeKeepsExistingBrowserPanesOnTheSharedJar`) | File from before jars (table dropped, migration 5 row deleted) with one saved browser pane; reopen; run the upgrade again | Schema version is 5; the pane has the storage-jar override equal to global; the index holds the name once |
| jars-007 | upgrade-fresh-database-noop (`testAFreshDatabaseLeavesNewPanesOnTheirOwnJar`) | Fresh database with a saved browser pane, reopened | No storage-jar override for the pane; the setting's default is `pane` |
| jars-008 | upgrade-keeps-existing-override | Pane already has a storage-jar value (for example `pane`); run the upgrade | Value unchanged; the name is added to the index only if missing |
| jars-009 | pane-standardized-path | `standardizedPath("/tmp/wt/")` and `standardizedPath("/tmp/wt")` | Equal strings |
| jars-010 | pane-state-key-prefix, pane-state-node-id | Pane with owner O and node N, prefix `p.` | `stateNodeID` is O; `stateKeyPrefix("p.")` is `p.` + N + `.`; with no owner it is `p.` and the node id is N |
| jars-011 | live-nested-by-state-key, live-nested-needs-state (`testANestedBrowserPaneIsLiveWhileItsOwnerIs`) | Live node O has a state row whose key is the prefix + nested UUID + `.url` | A pane for the nested id is listed with owner O; with no state row it is not listed |
| jars-012 | live-ids-include-any-key-uuid | A state key under a live node contains a UUID of any pane type | `livePaneNodeIDs` contains that UUID (the reconciler side is `testAPaneJarIsKeptForAPaneKnownOnlyByAStateKey`, which keeps a pane jar whose node id is in the live node ids) |
| jars-013 | creation-dates-by-id, insert-stamps-created-at | Insert a jar; read the dates | The map has the jar id with a date near now |
| jars-014 | upgrade-corrupt-index-reset | Pane's override index holds the text `not json` | After the upgrade the index is `["<storage-jar name>"]` |
| jars-015 | malformed-row-skipped | A `browser_jars` row with a `repo_id` that is not a UUID is inserted by raw SQL | The record queries return no record for it and do not throw |

