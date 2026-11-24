
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | partial | Platform Compliance |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`platform-theming` is `partial`: the backdrop takes whatever color its owner supplies, so theming works when the owner re-applies it on a theme change, but the component itself does not track appearance changes (see `backdrop-snapshot`). `separation-of-concerns` passes because the component only pins, clips and paints; the color, the insets and the child all come from its owner. `unit-test-coverage` fails because no test beside the source constructs the component or asserts its pins, insets or backdrop; it runs only as part of the window-controller tests.

