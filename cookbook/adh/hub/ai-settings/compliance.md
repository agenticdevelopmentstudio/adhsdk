
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | Access Patterns |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | passed | Performance |

`separation-of-concerns` is `partial`: transport lives in the personas data module and the services
list in `useUserServices`, but the section, the create form, the editor, the models table and the pure
helpers (substitution, label, number format) share one component file. `unit-test-coverage` is
`partial`: `ServicesSection.test.tsx` covers the Save gate and the exit guard, and `ModelsTable.test.tsx`
covers the Available column, "No longer offered", a failed availability change and re-enabling; the
create modal, the template logic, the number and price formatting, and Connect and
Refresh have no test beside them. `error-response-handling` is `partial`: list, save, delete,
availability and create-form failures show a
message, a template failure degrades, but a failed Connect or Refresh is only reported (see the open
question on `refresh-models-failure`). `secure-storage` passes for the client: the API key is sent only
when typed, is shown in a password field and is never read back. `semantic-markup` passes: the models
table is a native table with header cells and the controls are native elements. `caching-strategy`
passes: the services list and the template catalog are each one cached resource, so panes share an entry
and a return to the pane paints from cache while re-reading.

