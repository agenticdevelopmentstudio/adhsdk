
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |

separation-of-concerns passes: the file holds a snapshot value and a pure position-tracking function; the terminal, its snapshots and the chat transcript live in `TerminalSession` and `TerminalChatSession` in the macOS target. unit-test-coverage is partial: six tests cover the cursor start, the echo, the shown prompt, trimming, the alternate screen and a clear, but none covers `init(fromTopOf:)`, an echo that does not match, a blank first row, a trimmed resume row, a cursor beyond the last line or the whitespace-only send, so vectors 007 to 018 rest on the source alone.

