
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | failed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Keyboard-navigable is failed because `TabButton`/`TabItemHostView` have no
key-view-loop or `keyDown` wiring (see Accessibility).
Screen-reader-support is partial: it holds for `.title` tabs, where
`TabButton` sets a real accessibility role, title, value, and a republished
close-button child, but no accessibility notification is posted for a
programmatic active-tab change — a fallback activation, or the sibling-selection
update across an edge's other tabs (see Accessibility). String-externalization
is failed because the close button's "Close Tab" accessibility description is
a hardcoded English literal (see Localization). `@MainActor` confinement, the
single-active-tab invariant, and the color-only selection cue are true of the
source (see Behavioral Requirements and Accessibility Options) but are not
compliance-catalog checks, so they are not listed here.

`separation-of-concerns` passes because `MultiTabbedViewController` only arranges the edge-docked tab groups and their visibility; tab content, persistence and window chrome come from callers. `unit-test-coverage` is `partial`: `MultiTabbed/MultiTabbedActiveTabTests.swift`, `MultiTabbedHostedItemTests.swift`, `TabCardStackTests.swift`, `TabBarAccessibilityTests.swift` and `TabBarStartInsetTests.swift` cover it, but not every edge-docking vector.

