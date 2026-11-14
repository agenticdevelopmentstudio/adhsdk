
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`semantic-markup` passes because the source renders the native `<h2>` element directly, giving it a correct implicit heading role. `dynamic-type-support` is partial because the source applies no font-size styling of its own — it defers text scaling entirely to consumer-supplied CSS classes, which the source cannot verify. `separation-of-concerns` is `passed` because the component is pure presentation over `children` with no business logic; `unit-test-coverage` is `failed` because no test exercises `user-settings/components/Header.tsx` — the candidate tests found by name test unrelated Swift/hub-client and other web code, not this component.

