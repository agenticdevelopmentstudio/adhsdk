
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.platform-compliance.platform-permissions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90cb6a83-7544-53ea-8d2c-30851b253122) | passed | Platform Compliance |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | partial | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy And Data |

`separation-of-concerns` passes because the pure model (`Permission`, `PermissionStatus`), the protocol (`PermissionChecking`), the injectable probe (`AutomationProbing`) and the system conformance are separate, and UI concerns (opening panes, naming apps) are left to callers. `unit-test-coverage` is partial: the Automation, notification and location mappings and the metadata are unit-tested, but `captureStatus`, `keychainStatus` and `KeychainPermissionLedger` have no tests in the given suites, and the live system calls are runtime-only. `explicit-error-handling` is partial because `request(.notifications)` discards the thrown authorization error and the raw keychain `OSStatus` is collapsed to a tri-state. `platform-permissions` passes because each permission is requested only on an explicit `request(_:)` call and `status(_:)` never prompts. `timeout-handling` is partial: location requests time out after 120 seconds, but the Automation and keychain dialogs block with no timeout. `data-integrity` is partial because of keychain-ledger-key-collision, where distinct service names can share one ledger record. `data-minimization` passes because keychain bytes are discarded after the read and the ledger stores only a grant string.

