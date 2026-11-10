
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | Platform Compliance |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`keyboard-navigable`, `focus-management`, `platform-design-language`, and `native-controls-preference` rest on the source wrapping the native `NSTextView`/`UITextView` directly, with the explicit, delegate-driven `focus()` path (mtpane-010/011); `unicode-support` and `input-sanitization` rest on the plain-text-only design (**use-plain-text-mode**), which stores and echoes text without parsing or executing it; `dynamic-type-support`, `contrast-ratio`, `touch-target-size`, and `rtl-layout-support` are `partial` because the source delegates font, color, sizing, and bidi behavior to the caller's palette/container and to native `UITextView`/`NSTextView` defaults, which this recipe cannot verify; `data-minimization` rests on the Privacy section's confirmation that the component collects, stores, and transmits nothing beyond the text the caller provides. `separation-of-concerns` is passed because both variants are pure presentation over the native text view — no parsing, formatting, or business logic lives in either file, and rendering (Markdown parsing/highlighting) is handled elsewhere by the controllers above this pane; `unit-test-coverage` is passed on the platform-specific `MarkdownTextPaneInputTests` (iOS and macOS), which drive the real `UITextView`/`NSTextView` input path and assert `onTextChange` fires, plus the shared `MarkdownViewerControllerTests`, which exercise `pane.text`, `pane.isEditable`, and `pane.attributedText` through a loaded viewer.

The component provides no accessible name. `textView` is private in both variants, and the public API (`text`, `attributedText`, `isEditable`, `focus()`, `applyTheme(_:)`) exposes no label-setting member, so a caller has no way to give the pane an accessible name — `UITextView`/`NSTextView` still supply their native role (text view/text area) and read their content back as the value, but not a name (see **screen-reader-support** above).

