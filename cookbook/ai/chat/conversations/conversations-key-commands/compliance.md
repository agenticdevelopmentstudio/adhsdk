
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`separation-of-concerns` passes because the component only declares commands;
the registry performs them and the window decides ownership.
`no-hardcoded-strings` fails because the titles are English literals with no
localization. `unit-test-coverage` is `partial`: in
`KeyCommands/KeyCommandsPanelHierarchyTests.swift`,
`testTheConversationsWindowListsItsSingleModeCommandsUnderTheMode` installs
the section with a resolver returning `nil` and checks the panel outline
(section title, the toggle command, the "Single Conversation Mode" heading and
the two selection commands in order), which covers section-identity,
toggle-shelf-command and single-mode-feature and uses the identifier
constants. No test checks default shortcuts, what each command passes to the
controller, run-time resolution, or the declined-key behavior.

