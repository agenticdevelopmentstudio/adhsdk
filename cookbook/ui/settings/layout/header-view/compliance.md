
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |

`contrast-ratio` is `partial`, not passed: `secondaryText`'s derivation enforces only a 3.0 minimum-contrast floor (`SemanticPalette.derive`, case `.secondaryText`) — below the 4.5:1 WCAG AA figure required for 11pt text — as a single, app-wide semantic token this file draws from rather than a value it computes itself (see Increase Contrast in **Accessibility Options**).

Separation-of-concerns is passed: `HeaderView` only pins one themed caption label to its edges and takes its title as a constructor argument, with no layout or settings policy. Unit-test-coverage is partial: no dedicated `HeaderViewTests.swift` exists; `KeyCommandsPanelHierarchyTests.swift` builds a real panel and asserts on each `HeaderView`'s `titleLabel.stringValue` in its outline helper, so the title text is covered indirectly, but sizing and constructor-trap behavior are untested.

