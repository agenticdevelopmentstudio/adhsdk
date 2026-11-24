
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | partial | Reliability |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | Security |

Notes: separation-of-concerns passes because `GitStatusProvider` delegates
status computation entirely to `client.status(in:)`/`GitStatus.parse` and
delegates nothing about presentation to itself; the color mapping lives in
its own extension, independent of the broadcaster. unit-test-coverage is
partial because `GitStatusProviderRefreshTests.swift` exercises the three
core delivery paths (main-thread broadcast, unavailable-on-failure,
drop-stops-delivery) but has no test for the coalescing/queued-refresh path
(`coalesced-overlap`, `bounded-burst-cost`) or for `GitFileStatus+Color`'s
mapping at all. explicit-error-handling passes because every throw site in
`load` is caught and mapped onto `GitStatusRefreshResult.unavailable`, with
cancellation handled as its own branch rather than falling through the
generic catch. graceful-degradation passes because a failed status check
reports `.unavailable` rather than crashing or substituting an empty status,
letting a consumer keep its last-good badges. error-recovery is partial
because `GitStatusProvider` itself performs no retry or backoff after a
failure — recovery depends entirely on some caller invoking `refresh()`
again (an FSEvents burst, a menu command), not on anything this file does on
its own. secure-log-output passes because the failure branch is built from
`logDescription` (or the error's type name), explicitly never from
`error.localizedDescription` or `GitClientError.commandFailed`'s raw
`standardError` text.

