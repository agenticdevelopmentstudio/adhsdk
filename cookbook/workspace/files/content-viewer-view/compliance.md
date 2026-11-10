
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | passed | Internationalization |

The accessibility statuses are partial because this view relies entirely on SwiftUI's default `Text`/`Image` accessibility behavior — it sets no custom label, trait, or accessibility notification of its own, including no explicit notification when the selection changes (see the Accessibility section's Announce state changes item). Dynamic-type-support is partial because text scales with the theme's own `sizeScale` preference rather than the system's native Dynamic Type category, and the two icon sizes do not scale with either. `no-hardcoded-strings` failed because the computed type description strings (`Directory`, `Package`, the per-extension names, and the `<EXTENSION> File` fallback — see Localization) are `String` values passed to `Text(_:)` with no localization lookup; the seven fixed grid/placeholder labels are literals passed directly to `Text("…")`, which SwiftUI does look up as a `LocalizedStringKey`. The internationalization passes hold because every string is plain Unicode `Text`, and the grid's leading/trailing alignment mirrors automatically for right-to-left locales.

`separation-of-concerns` passes because `ContentViewerView.swift` only presents a node it is handed: a placeholder view when nothing is selected and `FileDetailView` for a selected `FileTreeNode`, with the byte-count and date formatting and theme lookups kept inside the view and no file reading, selection tracking or tree state of its own. `unit-test-coverage` fails because no test in the repo's test targets constructs `ContentViewerView`, its placeholder, or `FileDetailView`; the nearby `FileBrowser` tests exercise the tree controller, editor state and preview loader instead.

