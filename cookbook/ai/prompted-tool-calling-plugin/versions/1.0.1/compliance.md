
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.performance.progress-indication](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6ba6685b-9d35-5eb2-96e7-afbccd1e5848) | partial | Performance |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |

`separation-of-concerns` passes because the plugin only translates between the tool protocol and plain text, leaving transport, provider and tool execution to others. `unit-test-coverage` is partial: the suite covers pass-through, prompt building, history, a split block and a malformed block, but no test drives an unclosed tag, several calls, a native tool use, a decoder with no end, or the wrap-nothing failure. `explicit-error-handling` passes: a plugin built with nothing wrapped fails every request with a described error, and a bad block is kept visible rather than dropped. `progress-indication` is partial because the decoder emits nothing until the reply ends, leaving the caller to show a busy state. `input-sanitization` is partial: model output is parsed as JSON in a `try` and falls back to prose, but call names are not checked against the tools that were offered, so that check belongs to whatever executes the calls.

