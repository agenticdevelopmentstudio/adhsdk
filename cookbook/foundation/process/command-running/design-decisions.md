
**Decision**: `capture` has a protocol default built on `run` that returns the merged output as stdout.
**Rationale**: Per the source comment, doubles that only implement `run` still need a working `capture`; the default keeps a one-method test recorder valid. The cost is that such a double never shows a separate stderr.
**Approved**: pending

**Decision**: Launch failure and timeout both report status -1, with the cause in the text.
**Rationale**: The result is a simple pair, and launch jobs treat any non-zero status as failure. The source states "a timeout is never success", because a child that traps `SIGTERM` can still exit 0. The cost is that a caller must read the text to tell a launch failure from a timeout, and an undecodable stream becomes an empty string with no signal. This is accepted debt; it is revisited with a typed outcome on the result when a caller needs to branch on the cause instead of reading text.
**Approved**: pending

**Decision**: The backstop is 600 seconds and is a constructor setting, not a per-call argument.
**Rationale**: The source calls it a "backstop for a wedged helper so a caller fails instead of hanging forever; the default is far past any legitimate helper run". It is a safety net, not a tuned limit for any one command.
**Approved**: pending

**Decision**: A bare command name is resolved by this type against the child's `PATH`, not left to the operating system.
**Rationale**: The launcher takes a path only. The lookup runs against the replacement environment's `PATH` when one is given, so a command is found as a shell would find it with that environment. A miss keeps the name so the launch error carries the failure text.
**Approved**: pending

**Decision**: The blocking work runs at default quality of service, enforced.
**Rationale**: The source comment says the drain threads run at default, and waiting on them from the caller's (often main-thread) class is a priority inversion.
**Approved**: pending

