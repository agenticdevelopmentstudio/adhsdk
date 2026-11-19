
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | platform-compliance |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | accessibility |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`native-controls-preference` and `platform-design-language` rest on
`textField` being an unmodified `NSSecureTextField` with AppKit's default
bezel styling (**masks-entry-with-secure-field**); `keyboard-navigable`,
`idempotent-operations`, and `separation-of-concerns` rest on behavior that
is `TextEditView`'s concern and out of this recipe's scope (the field's
inherited, unmodified `NSControl` tab order, **skips-redundant-commits**,
and the view holding no persistence or business logic of its own); `screen-
reader-support` is `partial` because `textField` has no accessibility label
linking it to `label`'s title text — see Label requirements in
Accessibility above; `contrast-ratio` is
`partial` because the inherited placeholder-text color clears only a 1.6:1
floor against WCAG's 4.5:1 threshold (see
design-decisions ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c))).

No test in the repository's test targets constructs `SecureTextEditView`, so `unit-test-coverage` is `failed`: a search of `AgenticDeveloperHubSDKMacOSTests` and the other test targets for the type name finds nothing. Its only behavior, masking, is not asserted; the inherited text-row paths are covered by `RecordFieldRefreshTests.swift` for `TextEditView` only.

