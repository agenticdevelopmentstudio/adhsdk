
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| claude-status-line-001 | install-writes-newer | No installed copy, a versioned bundled copy; `testInstallWritesAnExecutableDispatcher` | `dispatch.sh` written with an executable mode and `wrote` true |
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
| claude-status-line-012 | adopt-keeps-command, adopt-noop, adopt-replaces-earlier | The shared adopt cases; `testAdoptFollowsTheSharedCases`, `testConformanceWithClaudeHelpers` | Names, replacements and no-op results match the Python implementation's cases |
| claude-status-line-013 | dispatcher-command-shape, adopted-name, dispatcher-version | The shared conformance cases; `testConformanceWithClaudeHelpers` | Each predicate and the version reading give the same answers as the Python implementation |
| claude-status-line-014 | entries-listing | Adopted and own renderers run by the real dispatcher; `testTheDispatcherRunsAdoptedAndOwnRenderersInNameOrder` | Output appears in name order |
| claude-status-line-015 | last-error, error-record-meaning | No record, then a record with text, a whitespace-only record and an invalid name `../errors/stenographer`; `testLastErrorReadsTheDispatchersRecord` | nil with no record, the record's trimmed text, nil for the blank record, nil for the invalid name |

