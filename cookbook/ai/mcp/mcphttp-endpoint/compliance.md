
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.security.secure-authentication](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1d5c23d5-9a26-57fb-a23d-358271e4204a) | passed | Security |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | Security |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | Access Patterns |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | Reliability |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | passed | Reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | Security |

`secure-authentication` passes on the constant-time bearer check made before the body is read. `secure-log-output` passes because the log lines carry only path, status and port. `timeout-configuration` and `timeout-handling` pass on the injectable 120 second timeout that is forwarded into the SDK as a real cancellation. `error-recovery` passes on the failed-start cleanup and the fallback to an ephemeral port. `separation-of-concerns` passes: the SDK keeps the protocol, FlyingFox the socket, `MCPStatelessHTTPHandler` the socket-free host policy (ids, cancellation, collected body) and this actor the token, route and lifecycle. `unit-test-coverage` is partial: the suite covers routing, auth, id round-trips, cancellation and the port fallback, but no test drives `stop()` during `start()`, a second `start()` during a stop, or the array and unparseable bodies (the null, boolean and fractional ids have tests). `secure-transport` is partial by design: traffic is plain HTTP, confined to the loopback address and guarded by the bearer token.

