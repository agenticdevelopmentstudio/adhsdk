
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | partial | Reliability |
| [adc.check.artifact-formatting.ingredient-formatting.if-behavioral-requirements](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/192770a1-b6b6-5782-bc29-251a8a941272) | passed | Artifact Formatting |

`explicit-error-handling` is partial: `setMood`/`play`/`applyPose` raise a
catchable, byte-identical-message error on both platforms for the two
validated failure paths, but an unreachable/loader-guaranteed branch traps
the process on Apple (`preconditionFailure`/`try!`) instead of raising a
catchable error the way the TypeScript mirror does — see Design Decisions.
`graceful-degradation` is partial for the same asymmetry, mirrored: a
malformed `promote` input degrades safely to a skipped step on both
platforms, but the loader-guaranteed-unreachable branches degrade
identically only on the web side; on Apple they end the process instead.

