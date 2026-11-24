
| Check | Status | Category |
|---|---|---|
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Statuses rest on direct inspection of `SingleWindowController.swift`: native
`NSWindow`/`NSPanel` construction with no custom-drawn chrome
(native-controls-preference), an explicit accessibility identifier derived
from `windowID` (screen-reader-support), and no-op repeats of
`fitWindow`/`showWindow`/`ensureCurrent` when nothing has changed
(idempotent-operations).

`separation-of-concerns` is partial: frame persistence math lives in `WindowFrameManager`, lookup in `WindowRegistry` and window placement values in `WindowSpec`, but `SingleWindowController` itself still bundles window construction, restore and delegate wiring, content refit after a move, the HUD configuration and the singleton convenience in one class. `unit-test-coverage` is partial: `SingleWindowControllerTests.swift`, `SingleWindowControllerMoveRefitTests.swift`, `SingletonWindowControllerTests.swift` and `PerIDWindowControllerTests.swift` cover subclass configuration, lifecycle, centering, delegate timing, move refit and the singleton convenience, but nothing exercises the `HUDConfiguration` path (`configureAsHUD`).

