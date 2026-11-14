
| Check | Status | Category |
|---|---|---|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`separation-of-concerns` passes because the protocol carries only the decision of who
insets: the pane owns the setting and the fallback path, and the content owns its own
inset when it adopts the protocol. `unit-test-coverage` fails because no test beside
the source exercises the protocol, `applyResolvedSpacing()` or the two conformers;
the one nearby test, `PaneSpacingMigrationTests`, covers only the legacy padding
migration, so the vectors above are derived from the code.

