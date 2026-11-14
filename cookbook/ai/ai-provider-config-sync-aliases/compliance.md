
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`separation-of-concerns` passes because the file only maps names: the shape lives in Core, and sending and applying live elsewhere. `unit-test-coverage` is partial because `AIProviderConfigSyncTests` (`testRoundTrip`, `testDecodesMissingSelectionAsNil`) exercises the aliases through the plugin layer, but no test in the plugin layer's test target covers the optional `removedConfigIds` field (only the Core and Database test targets do) or asserts that the alias and the Core type are one type.

