
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |

`separation-of-concerns` passes because the type only carries a row and folds `kind` into two derived flags; extraction, filtering, paging and rendering stay in the daemon and the window. `unit-test-coverage` is partial because `ConversationEntryDTOConformanceTests` (`AgenticDeveloperHubSDKCoreTests/Stenographer/ConversationEntryDTOConformanceTests.swift`) tests vectors 001 to 008 and 011; vector 009 is skipped there (the daemon builds the ids; covered by `ConversationFeedTests`) and vector 010 is skipped (`ConversationExtractor` lives in the daemon target, not Core). `graceful-degradation` passes because a missing `termProgram` from an older daemon decodes to the empty string instead of failing the feed.

