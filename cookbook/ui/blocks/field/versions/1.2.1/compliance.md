
| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`screen-reader-support` rests on the shared `Label` giving the control a
meaningful, programmatic name from the caption (**associate-label-implicitly**)
and on `errorId` naming the error line for `aria-describedby`
(**name-error-line**); `semantic-markup` rests on `Field` composing native
`<label>` and text elements rather than custom ARIA roles.
`separation-of-concerns` passes: `field.tsx` has no logic beyond choosing
which layout classes to apply and composes `Label`/`FieldFootnote` rather
than reimplementing them. `unit-test-coverage` passes — `field.test.tsx`
asserts both `layout="inline"` and the default `"stacked"` layout, covering
the caption's right-alignment and the footnote's grid-column placement in
each.

