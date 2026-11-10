
| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`screen-reader-support` and `keyboard-navigable` rest on `Field`'s label
wrapping and the native `<label>`/`<input>`/`<button>` elements in
`CrudRecordForm.tsx`. `platform-theming` rests on `fieldCaptionClass` and the
shared classes drawing every color from `apt-*` tokens (no raw hex).
`no-hardcoded-strings` fails because the `Cancel`/`Save`/`Saving…`/`Close`
labels and the required/number/JSON error messages in `CrudRecordForm.tsx` are
literal English strings with no localization call.

`separation-of-concerns` passes because `CrudRecordForm` generates fields from `CrudTableMeta` and hands the validated payload to its `onSubmit`-style callback, while fetching and persistence live in `useCrudResource` and the surrounding page. `unit-test-coverage` passes because `packages/web/packages/crud/src/__tests__/CrudRecordForm.test.tsx` exercises the form's field generation, validation and submit behavior.

