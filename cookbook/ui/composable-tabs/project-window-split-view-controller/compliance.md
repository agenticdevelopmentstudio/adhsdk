
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.performance.animation-frame-rate](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9eb9b4fc-2e44-5391-9445-d6e78caa874e) | passed | Performance |
| [adc.check.reliability.state-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6e64e2f2-28ad-55d5-a8ed-cee075366674) | passed | Reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`keyboard-navigable` is `partial`: the shelf-panel toggle is a keyboard path for showing, hiding and focusing the shelf, but the open question on `keyboard-divider-resize` records that no keyboard path moves the divider. `reduced-motion` fails because the slide never consults the system setting (see the open question on `Reduce Motion`). `platform-theming` passes because both backdrops come from the theme palette and are re-applied on a theme change. `animation-frame-rate` passes because the slide lays out once per display frame and ends by wall-clock progress. `state-recovery` passes because the shelf's visibility and width are persisted and restored at launch. `separation-of-concerns` is `partial`: the component delegates the shelf's contents, the pane shares and the window's reaction to callbacks, but it also owns the persistence writes, the slide engine and the window-width hold in one type. `unit-test-coverage` fails because the only test beside the source asserts the controller's type; no test drives a slide, a drag, a restore or a layout adoption.

