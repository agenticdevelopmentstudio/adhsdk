
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`keyboard-navigable` and `screen-reader-support` pass because this
component overrides no keyboard, focus, or accessibility method, leaving
the platform's default button's own compliant behavior intact.
`native-controls-preference` passes because the whole implementation is
the platform's own system pointing-hand and arrow cursors, with no custom
cursor image.

`separation-of-concerns` passes because `PointingHandButton` adds only the pointing-hand cursor over its bounds and leaves title, action and styling to the ordinary button it subclasses. `unit-test-coverage` is `failed`: a search of the Apple test targets finds no test file for `PointingHandButton`, so the cursor behavior is unpinned by automated tests.

