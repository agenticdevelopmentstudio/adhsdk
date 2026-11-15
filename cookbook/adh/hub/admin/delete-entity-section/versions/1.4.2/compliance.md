
| Check | Status | Category |
|---|---|---|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` passes: `delete-entity-section.tsx` renders the disclosure and two-phase dialog only; the destructive action is the caller-supplied `onConfirm`, and any navigation after deletion is the caller's. `unit-test-coverage` is `partial`: `deleteEntitySection.test.tsx` covers the default and reversible wording through both dialog phases, the archive versus trash glyph, the "Archiving…" busy label, and the non-Error rejection fallback, and the two busy/failure tests type the identifier only as a step toward clicking confirm, but no test asserts that the confirm button stays disabled until the typed text matches, or exercises the empty-`confirmValue` guard. `platform-theming` passes: every color in source is an `apt-*` token class with no raw hex value or `!important`. `focus-management` passes: the confirm flow rides the shared `Dialog` primitive with no override of its focus handling, and the type-to-confirm `Input` is labeled by a screen-reader-only `Label htmlFor`. `no-hardcoded-strings` fails: the copy ("Do you wish to proceed?", "Permanently", "This cannot be undone") is English JSX literal text with no translation call.

