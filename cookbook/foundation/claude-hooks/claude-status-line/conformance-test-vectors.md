
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| claude-status-line-001 | install-writes-newer | No installed copy, a versioned bundled copy; `testInstallWritesAnExecutableDispatcher` | `dispatch.py` written with an executable mode and `wrote` true |
| claude-status-line-002 | install-never-downgrades, install-writes-newer | Installed version higher, then lower; `testInstallUpgradesButNeverDowngrades` | Higher installed copy kept; lower one replaced |
| claude-status-line-003 | install-replaces-unversioned | Installed copy without a version line; `testAnUnversionedInstalledDispatcherIsReplaced` | Replaced by the bundled copy |
| claude-status-line-004 | install-missing-bundle | Bundle absent with and without an installed copy; `testAMissingBundledDispatcherThrowsOnlyWhenNoneIsInstalled` | `dispatcherMissing` thrown only when none is installed |
| claude-status-line-005 | install-unversioned-bundle | Bundle without a version line; `testAnUnversionedBundledDispatcherThrowsOnlyWhenNoneIsInstalled` | `dispatcherUnversioned` thrown only when none is installed |
| claude-status-line-006 | dispatcher-command | Dispatcher path under a temp directory; `testTheDispatcherCommandMatchesClaudeHelpers` | Equals the string claudehelpers' Python writes for the same path |
| claude-status-line-007 | register-replaces, unregister-both | Register as renderer, re-register as tap, unregister; `testRegisterSwitchesKindsAndUnregisterClearsTheError` | One file at a time; unregister removes the entry and its error record |
| claude-status-line-008 | register-replaces | Register the same command twice; `testRegisterSaysWhetherItChangedAnything` | First call true, second false |
| claude-status-line-009 | valid-name, entries-listing | Folder holding an invalid name; `testEntriesSkipInvalidNames` | The invalid name is not listed |
| claude-status-line-010 | owner-only-tree | Adopted entry; `testAnAdoptedEntryIsOwnerOnly` | Entry `0600`, directories `0700` |
| claude-status-line-011 | adopt-spares-taps | A tap named like the adopted name; `testAdoptNeverRemovesATapOfTheSameName` | The tap stays and the adopted renderer takes the next free name |
| claude-status-line-012 | adopt-keeps-command, adopt-noop, adopt-replaces-earlier | The `adopt` cases in adtoolkit's `tools/claudehelpers/tests/fixtures/statusline_conformance.json` (each lists starting entries, the command, the expected name and the expected renderers); `testAdoptFollowsTheSharedCases` | Names, replacements and no-op results match the Python implementation's cases |
| claude-status-line-013 | dispatcher-command-shape, adopted-name, dispatcher-version | The `isDispatcherCommand`, `isAdoptedName`, `isValidName` and `shellQuote` cases in adtoolkit's `tools/claudehelpers/tests/fixtures/statusline_conformance.json`; `testConformanceWithClaudeHelpers` | Each predicate and the version reading give the same answers as the Python implementation |
| claude-status-line-014 | dispatcher-contract | Adopted and own renderers run by the real dispatcher; `testTheDispatcherRunsAdoptedAndOwnRenderersInNameOrder` | Output appears in name order (an integration vector: the dispatcher, not this type, orders the output) |
| claude-status-line-015 | last-error, error-record-meaning | No record, then a record with text, a whitespace-only record and an invalid name `../errors/stenographer`; `testLastErrorReadsTheDispatchersRecord` | nil with no record, the record's trimmed text, nil for the blank record, nil for the invalid name |
| claude-status-line-016 | register-name-precondition | `register(.renderers, name: "../x", command: "c")` | Fails a precondition; nothing is written |
| claude-status-line-017 | entry-content, entry-lookup | Register `c` as a tap, then call `entry(named:)`; also call `entry(named: "../x")` | The file holds `c` plus one newline; the lookup returns `c` trimmed, nil for the invalid name |
| claude-status-line-018 | directory-layout, settings-lock-name | A Claude directory `D` | Entries are under `D/claudehelpers/statusline/renderers` and `.../taps`, errors under `.../errors`, the dispatcher at `.../dispatch.sh`, and the lock name is `.settings.lock` |
| claude-status-line-019 | write-creates-parents | Register into a Claude directory that does not exist | The directories are created with mode `0700` and the entry is written |
| claude-status-line-020 | write-failure-propagates | Make the entry directory unwritable, then call `register` | The call throws |
| claude-status-line-021 | error-descriptions | `dispatcherMissing("/p")` and `dispatcherUnversioned("/p")` | Descriptions are "The status-line dispatcher this build carries is missing at /p." and "The status-line dispatcher this build carries has no version line at /p." |
| claude-status-line-022 | unregister-both | `unregister` on a name with no entry | Returns false |
| claude-status-line-023 | install-refuses-shell | A bundled shell dispatcher at version 5, none installed; `testAShellBundledDispatcherIsNeverInstalledAsThePythonOne` | Throws `dispatcherShell` and writes no `dispatch.py` |
| claude-status-line-024 | remove-legacy-dispatcher | `dispatch.sh` and `dispatch.py` both present; `testRemoveLegacyDispatcherDeletesOnlyTheShellOne` | `dispatch.sh` is gone, `dispatch.py` remains, the call returns true |
