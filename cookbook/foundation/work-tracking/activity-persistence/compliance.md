
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |
| [adc.check.reliability.state-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6e64e2f2-28ad-55d5-a8ed-cee075366674) | passed | reliability |
| [adc.check.privacy-and-data.data-retention-policy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0c9cc813-244a-5dc1-8914-fd4710bb4943) | partial | privacy-and-data |

The protocol keeps storage separate from every work-tracking rule, which stays in the controller (review F14), so separation of concerns passes. Unit coverage passes: `ActivityPersistenceContract` runs fourteen checks against both hosts, `testRecoveredEndRules` pins the recovery rule, and the prune and known-roots tests cover the host-specific operations. Every operation throws rather than failing silently. Data integrity is partial: duplicate ids are refused and re-close keeps the first end, but timestamps are unvalidated strings, and an unparseable one silently deletes a span as sub-second. State recovery passes: `recoverActivity` closes every open span and idle interval after a crash without billing downtime. Retention is partial because prune deletes only derived spans and the cutoff is the caller's, so an underived span is kept indefinitely, and the protocol doc comment omits the idle-overlap exception both hosts apply.

