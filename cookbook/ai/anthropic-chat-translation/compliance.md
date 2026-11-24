
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | Access Patterns |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | Internationalization |

`separation-of-concerns` passes because the component only transforms bytes: it opens no connection, reads no setting and holds no credential, leaving transport, retry and timeout to the caller. `unit-test-coverage` passes because `AnthropicChatTranslationTests` covers request translation for system, user, assistant, tool, image and option paths, the non-streamed reply, error mapping, and streaming behavior including byte-wise feeding, CRLF, interleaving, `[DONE]`, mid-stream errors and double finish. `explicit-error-handling` is partial because structural failure throws a typed error, while lossy cases (dropped blocks, replaced bad tool arguments, dropped late fragments) give the caller no signal; these are deliberate, per the source's own comment. `error-response-handling` passes because every HTTP status maps to an Anthropic error type with a message, with an explicit fallback. `input-sanitization` is partial because the component checks structure, not content: tool arguments in a stream are forwarded unvalidated, and provider messages pass through as written. `no-hardcoded-strings` is partial because three English strings are written into the output (see Localization), though none is interface text.

