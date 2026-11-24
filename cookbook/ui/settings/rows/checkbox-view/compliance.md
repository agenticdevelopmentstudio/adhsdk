
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | platform-compliance |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | accessibility |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | partial | reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`keyboard-navigable` and `screen-reader-support` rest on `toggle` being an
unmodified `NSSwitch`/`NSControl` with `setAccessibilityTitleUIElement` set
(no focus, key-handling, or accessibility-role override anywhere in
source — see **inherits-native-keyboard-focus** and
**links-toggle-accessibility-title**); `idempotent-operations` is `partial`
because repeated commits of the same toggle value are a no-op
(**skips-redundant-commits**), but constructing a second observer against
the same `viewModel` is not idempotent — it silently overwrites the prior
`onChange` handler (**claims-sole-onchange-observer**).

`unit-test-coverage` is `partial` because there is no `CheckboxViewTests` file, but `SettingObservingTests.swift` (`testViewModelClosureInitDrivesACheckbox`) constructs a `CheckboxView` and checks its toggle state and write-through to the view model, and `EditableTableCardUpdateTests.swift` and `ConfigurationContributionPointTests.swift` build it inside groups and assert on the resulting hierarchy; the click-to-commit and external-change resync paths are not exercised directly.

