
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

The session, plugin loading, provider resolution and chat drawing sit in other
types, but this one controller also holds the settings storage, the status
rules, the model-list fetch and the options-sheet construction, so
separation-of-concerns is partial. `PersonaTerminalChatToolsTests` covers the
tool wiring and the tool caller only; no test covers the status rules, the
settings round trips, the model list or teardown, so coverage is partial. A
failed live fetch falls back to the template list, but a plugin that fails to
load is logged nowhere and surfaces only as the session's generic
`No AI provider is configured.` turn failure (`plugin-load-failure-silent`),
so error handling is partial. The controls carry accessibility identifiers but
not labels (the open question on `control-labels`), so screen-reader support is
partial. Every user-facing string is an English literal, so no-hardcoded-strings
fails.

