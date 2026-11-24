
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ai-config-push-ledger-001 | first-push-removes-nothing, last-pushed-empty | Fresh ledger; `removed(configured: [UUID()])`. | `[]` (test: testFirstPushRemovesNothing). |
| ai-config-push-ledger-002 | record-landed-union, removed-difference | Record a sync whose configs are first and second with `removedConfigIds` empty; then `removed(configured: [first])`. | `[second]` (test: testARecordedPushThenADroppedConfigurationIsRemoved). |
| ai-config-push-ledger-003 | configured-means-held | After that record, `removed(configured: [first, second])`. | `[]` (test: testAConfiguredButUnresolvedConfigurationIsNeitherRemovedNorForgotten). |
| ai-config-push-ledger-004 | record-landed-keeps-unresolved | Record a sync of only first, with empty `removedConfigIds`, after second was recorded. | `lastPushed()` is first and second (test: testAConfiguredButUnresolvedConfigurationIsNeitherRemovedNorForgotten). |
| ai-config-push-ledger-005 | record-landed-removals | Record first and second; then record a sync of first with `removedConfigIds` of second. | `lastPushed()` is first only (test: testARemovalDropsTheIdFromTheLedger). |
| ai-config-push-ledger-006 | key-namespace | Record under key `http`; call `removed(configured: [])` on a ledger with key `xpc` over the same store. | `[]` (test: testTwoLedgersWithDifferentKeysAreIndependent). |
| ai-config-push-ledger-007 | last-pushed-skips-malformed | Store the strings `not-a-uuid` and a valid UUID under the key. | `lastPushed()` holds only the valid UUID (test: testV7_malformedStoredIdsAreSkipped). |
| ai-config-push-ledger-008 | removed-order | Ledger holds three ids; none configured. | The result is in ascending `uuidString` order (test: testV8_removedIdsComeBackInAscendingUUIDStringOrder). |
| ai-config-push-ledger-009 | record-landed-removals | Record a sync with nil `removedConfigIds` and one config over a ledger holding another id. | The other id stays in the ledger with the new one (test: testV9_aNilRemovalListKeepsTheExistingIdsBesideTheNewOne). |
| ai-config-push-ledger-010 | record-landed-format | Record two configs, then read the raw entry. | An array of two UUID strings sorted ascending (test: testV10_theStoredEntryIsASortedArrayOfUUIDStrings). |
| ai-config-push-ledger-011 | record-landed-configs-win | Record a sync whose `configs` holds first and whose `removedConfigIds` also names first. | `lastPushed()` holds first (test: testV11_aConfigThatIsAlsoListedAsRemovedStaysInTheLedger). |
