
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| claude-hook-installer-001 | install-result, install-additive | Empty settings; `testInstallIntoEmptySettings`, `testInstallIdempotent` | First install returns `installed`; a second returns `alreadyInstalled` |
| claude-hook-installer-002 | hook-command-shape, hook-command-exit-zero, hook-command-absolute-helper | Helper `/Applications/Stenographer.app/Contents/Helpers/steno`, event `Stop`; `testCommandIsThreeLines` | Lines are the marker, `/Applications/Stenographer.app/Contents/Helpers/steno hook --event Stop`, and `exit 0` |
| claude-hook-installer-003 | hook-command-exit-zero | Every `HookEventType` case; `testCommandAlwaysExitsZero` | Each rendered command contains `exit 0` |
| claude-hook-installer-004 | hook-registration-shape | After install; `testAllHooksAreAsyncWithTimeout` | Every hooked event has a `command` hook with `async` true and `timeout` 10 |
| claude-hook-installer-005 | excluded-event-types, install-scrubs-excluded | Settings holding this owner's `WorktreeCreate` hook; `testScrubsStaleDelegationHooksOnInstall`, `testScrubPreservesThirdPartyDelegationHooks` | Own hook removed from the excluded type, a third party's hook kept |
| claude-hook-installer-006 | install-requires-helper | `helperIsExecutable` returns false; `testAMissingStenoLeavesTheHooksAlone` | Result is `failed`, settings unchanged |
| claude-hook-installer-007 | install-replaces-legacy | Settings with an `http` or bash-form hook of this owner; `testLegacyHTTPHookIsReplacedByTheCaptureHook`, `testMovedBundleHookCommandIsRewritten`, `testAForeignHookSharingTheGroupSurvivesABundleMove` | Replaced by the current command; the foreign hook in the same group survives |
| claude-hook-installer-008 | slot-adopts-foreign | Slot holds another tool's command; `testInstallAdoptsAForeignStatusLine` | Command kept as an `adopted` renderer, slot holds the dispatcher command |
| claude-hook-installer-009 | bundle-command-recognition | Slot holds a wrapper around the bundle's command; `testAWrapperAroundOurStatusLineIsForeign` | Treated as foreign and adopted, not replaced |
| claude-hook-installer-010 | uninstall-status-line-release | Only an adopted renderer remains after uninstall; `testUninstallHandsTheAdoptedStatusLineBack` | The adopted command is written back into the slot |
| claude-hook-installer-011 | uninstall-entry-order | Save fails; `testUninstallDeletesNoEntryWhenTheSaveFails` | No status-line entry is deleted |
| claude-hook-installer-012 | lock-timeout | Shared lock held past the timeout; `testASettingsLockHeldPastTheTimeoutFailsInsteadOfHanging` | `lockAcquireFailed` after the timeout |
| claude-hook-installer-013 | lock-files | Lock held then released; `testAHeldSettingsLockDelaysTheInstallUntilItIsReleased`, `testTheSharedLockIsTheOneClaudeHelpersTakes` | Install waits for release then succeeds; the shared lock is `.settings.lock` |
| claude-hook-installer-014 | load-settings | Missing, empty and invalid-JSON files; `testLoadSettingsReturnsEmptyForMissingFile`, `testLoadSettingsReturnsEmptyForEmptyFile`, `testLoadSettingsThrowsForInvalidJSON`, `testInstallReturnsFailedForCorruptSettings` | Empty dictionary, empty dictionary, thrown `invalidFormat`; install returns `failed` |
| claude-hook-installer-015 | save-settings | Existing mode and symlink; `testSettingsFileModeIsPreserved`, `testANewSettingsFileIsOwnerOnly`, `testASymlinkedSettingsFileStaysALink` | Mode kept, new file `0600`, link kept |
| claude-hook-installer-016 | modify-settings | Body changes nothing, and body throws; `testModifySettingsWithoutAChangeWritesNothing`, `testModifySettingsThatThrowsWritesNothing` | Nothing written in either case |
| claude-hook-installer-017 | capture-script-ownership, capture-script-safe-open | Symlink, wrapper mentioning the name on line two, foreign file; `testInstallKeepsASymlinkByThatName`, `testInstallKeepsAWrapperThatOnlyMentionsTheNameOnLineTwo`, `testInstallKeepsAForeignFileByThatName` | Each is left in place |
| claude-hook-installer-018 | set-display-throws-on-enable | Tracking disabled, nothing registered, then enable the display; `testTurningTheDisplayOnWithNothingRegisteredThrows` | Throws `statusLineNotRegistered` whose description contains "tracking is off"; the `statusLine` slot stays unset |
| claude-hook-installer-019 | tracking-marker, status-line-off-marker | Config named `adkd`; `testTheMarkerFilesAreNamedAfterTheConfiguration` | Markers are `.adkd-tracking-disabled` and `.adkd-status-line-off` beside `settings.json` |
| claude-hook-installer-020 | install-preserves-foreign | Two configurations on one file; `testBothMarkerSetsCoexistAndEachUninstallRemovesOnlyItsOwn` | Each uninstall removes only its own entries |
| claude-hook-installer-021 | registration-kind | Tap-only configuration; `testATapOnlyConfigurationRegistersATapAndNeverARenderer` | Registered as a tap with ` --capture-only` |

