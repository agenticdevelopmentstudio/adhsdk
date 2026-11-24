
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.privacy-and-data.third-party-disclosure](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/036c9768-1c60-543d-b692-4adb3d3c884f) | passed | Privacy |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | partial | Reliability |

`separation-of-concerns` passes because the component only resolves and shows an icon and leaves the fallback and surrounding layout to the caller. `unit-test-coverage` is passed because `favicon.test.tsx` has a test for every vector, favicon-001 through favicon-013; favicon-011 simulates the pre-hydration state in jsdom by stubbing `complete` and `naturalWidth` on the image. `screen-reader-support` passes because the image is decorative, with empty alternative text and `aria-hidden`. `third-party-disclosure` passes because the image is requested only from the linked site. `graceful-degradation` passes because every failure path ends in the fallback. `error-recovery` is partial because failures advance through the candidates but the counter is not reset when `href` changes, as the open question on the changing-href edge case records.

