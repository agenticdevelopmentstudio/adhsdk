
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`separation-of-concerns` passes because the type does exactly one thing, naming the credential kinds and their one key spelling, and holds no storage, network or UI of its own. `unit-test-coverage` is partial: no test file targets `ClaudeCredentialKind` directly; `AgenticDeveloperHubSDKMacOSTests/ClaudeAccounts/ClaudeLiveLoginRecordTests.swift` constructs accounts with each kind but does not assert the key or parse functions.

