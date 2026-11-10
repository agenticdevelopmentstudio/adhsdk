
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |

`keyboard-navigable` passes because the source overrides none of
`NSOutlineView`'s default keyboard/type-ahead handling
(`keyboard-and-typeahead-inherited`). `screen-reader-support` is partial: row
icons and the unsaved-changes marker carry explicit accessibility
descriptions, but the git-status badge does not (see Accessibility above).
`contrast-ratio` is partial: non-git colors resolve through
semantic theme roles whose actual contrast this file cannot show, and the
fixed git-status colors are not verified against theme backgrounds here.
`no-hardcoded-strings` and `string-externalization` fail because all ten
user-visible strings are `String` literals with no localization key (see
Localization above).

`separation-of-concerns` is partial: tree state (`FileTreeNode`, `FileTreeManager`) lives in the model layer, but `FileTreeOutlineViewController` itself holds the outline data source and delegate, the context menu (`NSMenuDelegate`), per-directory child watching (`ChildWatcher`), the open-request handling (`OpenRequest`) and its row views in one large file. `unit-test-coverage` is partial: `FileTreeContextMenuTests.swift`, `FileTreeOpenOnSelectionTests.swift`, `SelectionSyncTests.swift` and `FileTreeNodeTests.swift` construct the real controller and cover the menu, open-on-selection, selection sync and node behavior, but no test covers the row views, keyboard handling or child watching.

