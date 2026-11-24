
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Separation-of-concerns is passed: the window owns only list-to-pane mapping and selection, with chrome inherited from `SettingsWindow` and all model changes delegated to the owner through callbacks. Unit-test-coverage is partial: `RecordDetailWindowControllerTests.swift` has fifteen tests covering panes per record, selection, neighbour selection, the empty list, the footer, add and remove, the veto and single selection reports, but fixed panels, `onConfigurePanel` and the `confirm` and `reportFailure` defaults have no tests there.

