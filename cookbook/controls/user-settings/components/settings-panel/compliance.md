
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` is partial because one file holds selection state, persistence, pane registration, auto-selection and rendering for the root, the sidebar and the pane, although context and types are split into their own modules. `unit-test-coverage` passed because `SettingsPanel.test.tsx` has a passing test for every vector, settings-panel-001 to settings-panel-018. `keyboard-navigable` is partial because every enabled row is a native button reachable with Tab, yet the tab roles carry no arrow-key behavior. `semantic-markup` is partial because the navigation landmark, tab roles and `aria-selected` are present while the `aria-controls` and `aria-labelledby` targets are missing. `no-hardcoded-strings` fails because the sidebar navigation label is a literal in the component.

