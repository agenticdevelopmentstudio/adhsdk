
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.reliability.health-observability](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d4ece88d-eeff-5e3f-8823-d8c2929a35e0) | partial | reliability |

**Separation of concerns.** The module holds only the rule and its thresholds, with no React, I/O or rendering; the banner and hook apply it.

**Unit test coverage.** `snapshot-staleness.test.ts` covers the floor and scaling of `snapshotStaleMs`, the missing-input, fresh, stale, very-stale, interval-scaling, NaN and negative-lag paths of `snapshotFreshness`.

**Explicit error handling.** Unparseable dates are handled by a deliberate negated comparison documented in the source, never by an exception.

**Graceful degradation.** An older backend with no `probeIntervalMs`, or a monitor with no probes, degrades to the floor window or to no banner rather than a false alarm.

**Health observability.** Partial: the rule surfaces data freshness to the user, but by design it fails open on unparseable or `NaN` inputs, so a malformed snapshot produces no staleness signal; cycle-completion health is left to the backend's `/health`.

