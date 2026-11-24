
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | platform-compliance |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |

`native-controls-preference` and `platform-design-language` pass because
every control (`NSSearchField`, `NSTableView`, the checkbox `NSButton`) is
a stock AppKit control themed via `ThemeRole`, not a custom-drawn
substitute; `keyboard-navigable` passes because arrow keys, Return, and
Escape all reach the model through `PickerKeyboardController`;
`screen-reader-support` is partial because the multi-select checkbox
carries no accessibility label linking it to its row's title (see
Accessibility above); `separation-of-concerns` passes because all
filtering, selection, and checked-set state lives in the AppKit-free
`ExtensionQuickPickModel`, not in this view controller.

`unit-test-coverage` passes: the filtering, selection and checked-set logic is covered by `ExtensionQuickPickModelTests.swift`, the controller's row-click behavior (a separator click never accepts or checks, a real row accepts or toggles, a negative row is a no-op) by `ExtensionQuickPickViewControllerTests.swift`, and the `vscode.window` bridge by `MainThreadWindowQuickPickTests.swift`.

