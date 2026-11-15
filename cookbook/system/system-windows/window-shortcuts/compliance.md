
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |

Separation of concerns passes: the names file holds only the scheme data, the manager only maps key-downs to model calls, and all context logic stays in `SystemWindowContextsModel`. Unit-test coverage is partial: `SystemWindowShortcutNamesTests` covers wms-001 to wms-009 (name list, ordering, uniqueness, defaults) and `ShortcutManagerConformanceTests` covers wms-019 (registry reservation). The rest are skipped with reasons: wms-010 to wms-018 and wms-021 because `KeyboardShortcuts` offers no public way to fire a key-down (it needs a real Carbon hotkey event); wms-020 because customizing a shortcut writes `UserDefaults.standard`, which tests must not touch; wms-022 because the unified log cannot be read back reliably in a unit test process. Explicit error handling is partial: the manager discards the `Bool` results of add/remove and relies on the model's `lastError`, which is a reported path rather than a swallowed one. The reservation owner `"window contexts"` is a hardcoded English literal that reaches the user in the Settings conflict message. Keyboard navigation passes in the sense that every window-context action has a keyboard path, which is this component's whole purpose.

