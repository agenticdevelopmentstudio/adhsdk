
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |

separation-of-concerns passes: the file holds a value type, a constant list and one lookup; running-app lookup and activation live in `BringTerminalToFrontStrategy` and `WindowActivationTester`. unit-test-coverage is partial: `match` is reached only indirectly, through the conversation summary's app filter in `testAppMatchesAgentOrTerminalByPrefix`, and no test asserts the catalog's four entries, their bundle ids, the unknown-terminal nil or a custom catalog, so those vectors rest on the source alone.

