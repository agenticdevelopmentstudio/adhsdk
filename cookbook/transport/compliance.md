
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | partial | Reliability |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | Security |

`separation-of-concerns` passes: `APITransport` (the value type),
`DaemonContract` (the daemon's contract and constants), and
`TransportResolver` (the decision actor) each own exactly one responsibility,
and none reaches into another's internals. `explicit-error-handling` is
partial: the production probe folds every failure mode (refused connection,
DNS failure, timeout, non-200) into the same `false`/`.direct` outcome with
no distinguishable error surfaced to the caller (see
probe-failure-collapses-to-false). `unit-test-coverage` passes: all three
files are covered directly by `TransportResolverTests.swift`,
`DaemonTransportTests.swift`, and `DirectTransportTests.swift`, including
both hermetic (injected probe) and semi-hermetic (`MockDaemonServer`,
`StubURLProtocol`) paths. `fault-tolerance` passes: Direct is a documented,
guaranteed fallback, and a daemon probe failure never blocks `ADHClient`
construction. `graceful-degradation` is partial: the daemon-down path
degrades cleanly to Direct, but the concurrent-`resolve()` race and the
unvalidated `port` crash (both under Edge Cases) are unresolved, undegraded
failure modes. `secure-transport` is partial: the Direct path is always
HTTPS, but the Daemon path is plain HTTP — acceptable only because it is
restricted to `127.0.0.1` loopback traffic that never leaves the device (see
Privacy), a distinction this check does not itself encode.

