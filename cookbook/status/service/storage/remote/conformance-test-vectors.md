
Vectors 001 to 006 are traced to `storage-remote.test.ts`; 007 to 009 follow the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| storage-remote-001 | call-wire, value-roundtrip | Call a method with arguments including a `Date`, over a connected pair | The server receives the same values, and the result reaches the caller with the `Date` still a `Date` |
| storage-remote-002 | shape-walk, nested-dispatch | Call `telemetry.errors.<method>` on the stub | The nested store's method runs with its own `this` and its result returns |
| storage-remote-003 | error-flatten, error-rebuild | A method throws an `Error` with a `code` and a `cause` | The caller's rejection has the same message, and its `cause` has the same message and `code` |
| storage-remote-004 | single-queue | Two ports each issue calls whose handlers resolve out of order | The handlers run one at a time in arrival order across both ports |
| storage-remote-005 | unclonable-args | Call with a function among the arguments | Rejects with the clone error (the source also deletes the pending entry before rejecting) |
| storage-remote-006 | closed-port-client | The server side closes while a call is pending | The pending call rejects with `storage connection closed` |
| storage-remote-007 | queue-survives-errors | A call that throws, then a call that succeeds on the same port | The first rejects, the second resolves |
| storage-remote-008 | non-error-throw | A method throws the string `boom` | The caller receives an `Error` named `Error` with message `boom` |
| storage-remote-009 | slow-call-log | A call that takes 2,500 ms | One `[storage] slow call <path> 25xxms` warning is logged, and the reply is still delivered |

