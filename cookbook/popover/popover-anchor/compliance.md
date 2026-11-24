
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Accessibility checks are not listed because the anchor has no interactive element of its own; keyboard operability belongs to the composed trigger and panel (see [adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)). `PopoverAnchor.tsx` is nothing but a positioning `<div>` with no business logic (separation-of-concerns passed), and `PopoverAnchor.test.tsx` covers nine of the eleven conformance vectors (unit-test-coverage partial). anchor-009 and anchor-011 are skipped because they depend on layout and hit-testing, which jsdom does not provide.

