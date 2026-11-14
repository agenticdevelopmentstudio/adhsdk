
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | internationalization |

The type does one thing, formatting and keying events, with no I/O, so separation of concerns passes. Tests cover the idle, exited and quit text and the queue behavior that depends on the key, but not the tick lines, the started text, the guidelines and timeout text or the attribution accessor, so unit-test coverage is partial. The strings are hardcoded English, but they are prompts for a language model rather than user-facing text, so that check is partial rather than failed.

