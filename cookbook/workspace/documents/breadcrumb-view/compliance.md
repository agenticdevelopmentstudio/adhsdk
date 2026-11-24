
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

The accessibility statuses are partial because the source sets only an accessibility identifier per crumb and leaves label, dynamic-text, and contrast behavior to AppKit's own defaults (a plain `NSButton` title and `NSColor.secondaryLabelColor`) rather than defining or verifying them itself, and because no accessibility notification accompanies a strip rebuild (see Assistive technology, above). The internationalization statuses for hardcoded strings and Unicode support are passed because the source has no hardcoded user-facing strings and displays crumb titles through `NSButton`'s native Unicode-capable text handling. `rtl-layout-support` is partial rather than passed: the strip's own leading/trailing anchors and `NSStackView` layout mirror automatically for right-to-left locales, but the chevron separator is drawn with the `chevron.right` SF Symbol, which does not mirror to point left in RTL — `chevron.forward` is the symbol that does.

`separation-of-concerns` passes because `BreadcrumbView` only derives crumbs from a file URL and the project root and reports a selected crumb's directory, with the directory listing delegated to `BreadcrumbPopoverViewController`. `unit-test-coverage` is partial: `BreadcrumbViewTests.swift` covers the empty editor, crumbs relative to the root, a file outside the root and selecting a crumb, but not popover presentation or dismissal.

