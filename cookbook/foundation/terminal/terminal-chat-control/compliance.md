
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |

separation-of-concerns passes: the enum holds the wire shapes, shared numbers and the resolver; answering requests lives in `TerminalChatDirectoryToolSource` and running commands in `TerminalChatSession`. unit-test-coverage passes: every vector (001 to 012, 021, 024 and 025) is covered by `TerminalChatControlConformanceTests.swift` (`Tests/AgenticDeveloperHubSDKCoreTests/Terminal/`). data-minimization passes: the protocol carries only the fields each action needs, and the listing conceals the project and directory as the terminal does.

