
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.user-safety.safe-defaults](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dd43bec7-e292-559a-81e3-c0cf59156abe) | passed | user-safety |

separation-of-concerns passes: the file maps a session to a conversation reading and decides send eligibility; storage, transport and the terminal injection itself are other types. unit-test-coverage is partial: `ConversationSummaryDTOTests` covers status, home-relative paths, summary fields, app matching, work in progress and the send refusals, but no test covers `ConversationInfoDTO`'s raw fields, `terminalName`, the unsupported-terminal sentence or the unparsable-timestamp fallback, so vectors 022 and 023 rest on the source alone. safe-defaults passes: any unreadable or ambiguous state refuses a send rather than permitting it.

