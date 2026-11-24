
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | passed | Internationalization |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |

`screen-reader-support` is partial because both footer buttons have an empty
title and an image built with `accessibilityDescription: nil`, with no
explicit accessibility label set in source (see Accessibility);
`keyboard-navigable` passes because both are stock `NSButton`s with no
override disabling AppKit's default keyboard focus/activation.
`string-externalization` and `no-hardcoded-strings` fail because all five
user-facing strings are literal `String`s assigned to `toolTip`/`prompt`/
`message` (see Localization); `rtl-layout-support` passes because the layout
uses only `leadingAnchor`/`trailingAnchor` constraints, which AppKit mirrors
automatically for right-to-left locales. `data-minimization` passes because
`directories`/`selection` change only in response to an explicit user action
(the open panel, or a click in the tree), never automatically (see Privacy).

`separation-of-concerns` passes because `FileBrowserViewController` composes the browser from separate parts, with per-root tree state in `FileTreeManager`, the outline in `FileTreeOutlineViewController`, the roots list in the `FileBrowserRootsModel` observable object, and pane teardown and selection description in the `PaneContentTeardown` and `PaneSelectionDescribing` extensions. `unit-test-coverage` is partial: `FileTreeManagerInjectedProviderTests.swift` constructs the real controller to check provider injection and per-root scoping, and `FileBrowserRestorationStateTests.swift` and `SelectionSyncTests.swift` cover the restoration state and selection sync it relies on, but no test drives its layout, multi-root header, or teardown.

