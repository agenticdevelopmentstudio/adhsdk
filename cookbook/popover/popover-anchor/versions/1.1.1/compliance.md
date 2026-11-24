
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | failed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

The anchor closes only via `onMouseLeave`; nothing in `PopoverAnchor.tsx` offers a keyboard-equivalent way to dismiss the group, so keyboard operability depends entirely on whatever the composed trigger and panel add on top of it (see [adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)). `PopoverAnchor.tsx` is nothing but a positioning `<div>` with no business logic (separation-of-concerns passed), but no test file exercises it at all (unit-test-coverage failed).

