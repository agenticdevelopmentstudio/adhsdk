
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`separation-of-concerns` passes because the component only declares commands;
the registry performs them and the window decides ownership.
`no-hardcoded-strings` fails because the titles are English literals with no
localization. `unit-test-coverage` is `partial`:
`KeyCommands/KeyCommandsPanelHierarchyTests.swift` covers the panel outline,
and `ConversationsWindow/ConversationsKeyCommandsConformanceTests.swift`
covers every vector by id. Skipped: conversations-key-commands-009
(confines-to-ui-thread), because the component is `@MainActor` and a use from
another thread is rejected at build time. The run-for-real halves of
conversations-key-commands-005 (the selection moves by -1 and +1) and
conversations-key-commands-008 (a controller that accepts reports taken) need
a key window and skip themselves where the test runner cannot make one.
