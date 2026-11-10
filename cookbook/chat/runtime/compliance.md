
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | partial | Reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | partial | Reliability |

`explicit-error-handling` is partial: `submitMessage` and `respondToWidget`
surface backend failures as an `error` update and a re-thrown rejection, but
an `inboundEvents` iterator rejection is surfaced once and then the event
loop halts permanently with no further signal (see event-loop-recovery).
`separation-of-concerns` passes: `DefaultOrchestrator` (view-model state),
`InMemoryPermissionStore` (permission memory), and `ScriptedBackend` (test
transport) each own exactly one responsibility behind the `Backend`/
`PermissionStore` interfaces, and `DefaultOrchestrator` never reaches into
either implementation's internals. `unit-test-coverage` is partial:
`scenarios.test.ts` exercises `DefaultOrchestrator` extensively (18 test
cases) and, through it, `InMemoryPermissionStore` and `ScriptedBackend`
indirectly, but neither `InMemoryPermissionStore` nor `ScriptedBackend` has a
dedicated test file of its own — `close()`'s queue-draining behavior and
`send()`'s id-minting are untested directly (see ccr-023 and ccr-024).
`fault-tolerance` is partial for the same reason as `explicit-error-handling`:
the scheduler-equivalent here (the event-loop task) has no catch-up or retry
mechanism once its source throws. `graceful-degradation` is partial: known,
recognized failures (a rejected `send`, a rejected `submitWidgetResponse`, an
unrecognized permission/widget id) degrade cleanly to a documented no-op or
error signal, but an unrecovered inbound-stream failure and the
gating/observing hook surface (see the open question on hook-and-permission-enforcement) leave no
degraded-but-functioning path — they leave the runtime either fully working
or silently missing a whole mechanism.

