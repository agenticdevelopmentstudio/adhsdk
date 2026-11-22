
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | passed | access-patterns |
| [adc.check.access-patterns.pagination-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/e29ce31a-67cb-5690-b2ca-b1065ccdaf1a) | passed | access-patterns |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | security |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.artifact-formatting.ingredient-formatting.if-frontmatter-complete](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/083aeeb8-a2fa-5fbc-a3e6-82df9a653872) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-behavioral-requirements](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/192770a1-b6b6-5782-bc29-251a8a941272) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-test-vectors](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/91ba975a-1f6a-5a85-8652-26e76cf324f4) | passed | artifact-formatting |

The file holds only wire shapes and pure helpers, with no I/O, persistence or UI, so separation of concerns passes. Error handling is explicit: decoding failures throw, and the one custom refusal names the valid values. API conventions pass through consistent optional-means-absent semantics, backward-compatible defaults and a single key strategy. Pagination is supported with `afterId`/`beforeId` cursors and a clamped `limit`. Data minimisation passes because no type can hold a secret, though item keys still carry account emails. Unit test coverage is partial: `retriedAccount`, the effective limit, the rule filter cases, the verbatim account and the snake_case, secret-free status encoding are exercised by `AccountRouterRecordTests` and `AccountRouterRoutesTests`, but the status decoder's per-key defaults, `isRoutable`'s rejections and the query decoder's unknown-rule error are covered only indirectly through daemon routes or not at all. Input sanitisation is partial because the query clamps `limit` and refuses unknown rules, but the preference DTO carries out-of-range values unvalidated and relies on the daemon. The unknown-rule sentence is a hardcoded English literal, so no-hardcoded-strings fails.

