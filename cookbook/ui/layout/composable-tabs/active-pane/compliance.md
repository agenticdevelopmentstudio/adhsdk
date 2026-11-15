
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |

`focus-management` passes because every pointer-driven activation is
paired with a standard `NSResponder` focus change, with no private
accessibility-bypassing mechanism. `contrast-ratio` is `partial` because
the actual color values behind `projectPaneBackdrop`, `projectPaneOutline`,
and `projectActivePaneOutline` are chosen per theme, outside this file, per
the contrast requirement and its pending decision.

`separation-of-concerns` passes because `ComposableTabsActivePane` only tracks which pane is active and draws the pane backdrop and outline from theme roles; what a pane contains and what activation means to the content belong to the panes and the controller. `unit-test-coverage` is `partial`: `ComposableTabs/ComposableTabsActivePaneConformanceTests.swift` covers 51 of the 54 vectors, driving the tracker and the pane backdrop through real windows and pointer events sent with `NSApp.sendEvent`. Skipped: CTA-39 (the highlight override lives on the active theme, which a test cannot swap per pane), CTA-50 (a window belonging to another application cannot be created from inside the test process) and CTA-54 (main-actor isolation, enforced at build time). Tests that need a key window, a window held apart from the key one, or a sheet that takes key skip themselves where the environment cannot provide one. CTA-52 is checked in a closed window, the one place a window can have panes and no active id, so it shows the unclaimed outline colour without a focused window. `ComposableTabs/ComposableTabsPaneChromeTests.swift` also pins the backdrop colour, the 2-point fill inset and the fill being the first subview.

