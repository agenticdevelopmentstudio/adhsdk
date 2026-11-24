
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`screen-reader-support` is partial because the component registers no
accessibility-grouping role for its row list (see Accessibility);
`keyboard-navigable` passed because the source overrides
no key-view loop, first responder, or key-equivalent, leaving AppKit's
automatic tab order across the arranged rows intact.

`separation-of-concerns` is `passed` because `PermissionsPanelView` only arranges one `PermissionRowView` per permission and decides when to refresh (on appearing, on app reactivation and after an action); status reading belongs to the injected `PermissionChecking` and card rendering to the row. `unit-test-coverage` is `failed` because no test references `PermissionsPanelView`: `PermissionRowViewTests.swift` covers only the row, so the panel's newest-refresh-wins serialization and its activation observer have no test.

