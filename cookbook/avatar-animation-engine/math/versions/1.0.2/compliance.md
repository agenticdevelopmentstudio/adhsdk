
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.artifact-formatting.ingredient-formatting.if-behavioral-requirements](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/192770a1-b6b6-5782-bc29-251a8a941272) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-test-vectors](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/91ba975a-1f6a-5a85-8652-26e76cf324f4) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-platform-notes](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90c2d8c2-cf79-5465-bffd-54f9fb1453bc) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-design-decisions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f5b5cbe6-22e8-5954-a18d-0362ee387941) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-change-history](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/14bf2d1d-875b-5e58-b43d-be492c9f941a) | passed | Artifact Formatting |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |

`explicit-error-handling` is `partial`: `parseHex`/`resolve`/`mix` all raise
catchable errors, but `Prng.pick` on Swift fails via an uncatchable
`preconditionFailure` rather than a catchable error for the same misuse the
web's `pick` throws for — see Design Decisions and the concurrency/ordering
open question in Edge Cases.

