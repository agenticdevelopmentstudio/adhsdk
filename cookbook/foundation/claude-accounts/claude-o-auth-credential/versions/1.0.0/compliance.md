
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | Reliability |

`separation-of-concerns` passes because the type only describes the credential shape and the milliseconds-to-seconds view; custody (keychain) and evaluation (expiry policy) live in other layers. `unit-test-coverage` is partial: no test file targets `ClaudeOAuthCredential` directly. `AgenticDeveloperHubSDKMacOSTests/ClaudeAccounts/ClaudeLiveLoginRecordTests.swift` builds credentials and compares live to saved ones, so equality is exercised indirectly, but the seconds conversion and the optional-field defaults have no assertion.

