
The endpoint is a four-phase state machine, `idle`, `starting`, `running` and `stopping`, with the port observable only while running.

| State | Entered when | Behavior |
|-------|-------------|----------|
| idle | Construction; after `stop()` completes; after a failed `start()` | `start()` begins binding. `stop()` runs the teardown (nothing to close, but it still stops the `HostMCPServer`) and ends idle. `port` is nil. |
| starting | `start()` begins | A second `start()` throws `alreadyStarting`. `stop()` records a stop request and returns. When binding finishes the stop request makes `start()` tear down and throw `stoppedWhileStarting`. |
| running | The listener is confirmed and the port recorded | `start()` returns the same port. `stop()` begins tearing down. Requests are served. |
| stopping | `stop()` begins | `start()` throws `alreadyStarting`. A second `stop()` returns at once. Ends in idle. |

Transitions: idle to starting on `start()`; starting to running on a confirmed bind; starting to idle on any `start()` failure or a recorded stop; running to stopping and then idle on `stop()`.

