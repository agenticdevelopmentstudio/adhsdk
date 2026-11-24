
| Check | Status | Category |
|---|---|---|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` passes: `delete-entity-section.tsx` renders the disclosure and two-phase dialog only; the destructive action is the caller-supplied `onConfirm`, and any navigation after deletion is the caller's. `unit-test-coverage` passes: `deleteEntitySection.test.tsx` carries one test per integration vector (T1 to T19), including the exact-identifier gate (T5), the empty-`confirmValue` guard (T7), the busy lock (T8, T17), inline errors (T9, T16), reset (T10), the reversible copy and glyph (T11 to T15) and the article choice (T18, T19). `platform-theming` passes: every color in source is an `apt-*` token class with no raw hex value or `!important`. `focus-management` passes: the confirm flow rides the shared `Dialog` primitive with no override of its focus handling, and the type-to-confirm `Input` is labeled by a screen-reader-only `Label htmlFor`. `no-hardcoded-strings` fails: the copy ("Do you wish to proceed?", "Permanently", "This cannot be undone") is English JSX literal text with no translation call.

