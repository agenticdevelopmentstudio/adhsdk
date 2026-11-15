
| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | passed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`semantic-markup`, `screen-reader-support`, and `keyboard-navigable` rest on the real
`<table>`/`<thead>`/`<tbody>`/`<th>` markup, the `aria-label="Row actions"` header, and
the real, focusable `<button>` elements with visible text labels (`CrudTable.tsx`);
`dynamic-type-support` rests on the component's text sizing using `rem`-based Tailwind
classes (`text-sm`, `text-[0.7rem]`, `text-xs`) rather than fixed pixel sizes;
`contrast-ratio` is partial because the source only names `apt-*` theme tokens
(`text-apt-text`, `text-apt-text-dim`, `text-apt-border`) without the underlying color
values, so the actual ratios can't be confirmed from this file; `no-hardcoded-strings`
is failed because `New`, `Edit`, `Delete`, `Loading…`, `No rows yet.`, and the
row-count text ("N row"/"N rows") are all literal, unwrapped English strings in
`CrudTable.tsx`.

`separation-of-concerns` passes because `CrudTable` is presentational: `rows`, `loading`, `error`, `canWrite` and every action callback are props, and fetching, confirmation and permission decisions live in `useCrudResource` and the caller. `unit-test-coverage` is `partial` because `packages/web/packages/crud/src/__tests__/CrudTable.test.tsx` covers `displayColumns`, `cellText`, the loading, empty and error states, the New/Edit/Delete callbacks, and the read-only mode (`drops New and Delete and turns Edit into View when the viewer may not write`), but no test passes `readOnlyNote` or asserts the default note text, and none pins that colors are the theme's token values.

