
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | Privacy and Data |

`outline-allows-empty-selection`/`return-key-activates-selection`/`alternate-return-path-activates-selection`, this file's exclusive use of `ThemedOutlineView`/`NSOutlineView`/`ThemedLabel`/`NSTableRowView`, and the absence of any logged `ContributedTreeItem` field or user string in `timeout-logged`'s one log line ground the `passed` rows. The missing state-change announcements described under **Announce state changes** have no dedicated check in the catalog.

`separation-of-concerns` passes because `ExtensionTreeViewController.swift` splits the work across distinct types: the `ExtensionTreeViewController` wrapper only resolves the provider and swaps placeholder for outline, `ExtensionTreeOutlineViewController` owns the outline and its data-source/delegate callbacks, `ExtensionTreeRow` is the identity-stable row model, and all data and activation come from the `ExtensionTreeDataSource` protocol rather than from the extension host directly. `unit-test-coverage` is partial: `ExtensionTreePaneLoadingTests.swift` (budgeted and cached child asks, a branch claimed by a second parent, a superseded pane's teardown), `ExtensionTreeRowTableTests.swift` (row identity, orphan holding and pruning, one-shot auto-expansion) and `ViewsContributionPointTests.swift` (the placeholder-then-resolved wrapper) exercise the loading and row-table logic, but no test drives the outline's keyboard activation (`insertNewline`/`keyDown`), chrome updates, visibility reporting, or selection restoration.

