
**Decision**: `GIT_OPTIONAL_LOCKS=0` is set on every call.
**Rationale**: Per the `ReadOnlyGit` type doc comment in `ReadOnlyGit.swift`, a status line re-renders constantly and a background `git` that grabs the index lock to refresh the stat cache would race the user's own commit, rebase or add in the same worktree. These calls only read git state, so they never need the index.
**Approved**: pending

**Decision**: Every failure collapses to the empty string rather than throwing or returning a result type.
**Rationale**: The callers are display and fingerprint code that treat "no answer" and "nothing" alike; the `ReadOnlyGit` type doc comment in `ReadOnlyGit.swift` states the contract (a non-zero exit, a hang past the limit, or a spawn error collapse to the empty string). The cost is that a caller cannot tell a failure from empty output.
**Approved**: pending

**Decision**: The limit is 5 seconds.
**Rationale**: Per the comment on the private `timeout` constant in `ReadOnlyGit.swift`, a status line re-renders constantly, so a `git` that has not answered within five seconds is dropped rather than waited on.
**Approved**: pending

**Decision**: There are two forms, `git(_:)` that trims and `rawGit(_:)` that does not.
**Rationale**: Per the doc comment on `rawGit(_:)` in `ReadOnlyGit.swift`, `git status --porcelain` has a two-column `XY` prefix, so an unstaged-only change on the alphabetically first path starts with a literal space; trimming eats it and turns a 24-byte status into a 22-byte one that git never emitted and that hashes differently for a purely cosmetic reason. Every displayed value wants the trim, which is why the trimming form is the default.
**Approved**: pending

**Decision**: The command is started through `/usr/bin/env` with no shell, and `PATH` is repaired.
**Rationale**: Per the comments in `rawGit(_:)` and on `repairedPath(_:)` in `ReadOnlyGit.swift`, `env` resolves `git` on `PATH` without a shell. A GUI-launched status line inherits the minimal path `/usr/bin:/bin:/usr/sbin:/sbin` with no Homebrew; Apple's git shim lives at `/usr/bin/git`, but the common install directories are kept too.
**Approved**: pending

**Decision**: `repairedPath(_:)` is public.
**Rationale**: Per the doc comment on `repairedPath(_:)` in `ReadOnlyGit.swift`, a test that spawns its own `git` to build a fixture repository must repair `PATH` the same way; a fixture that cannot find `git` under Xcode's environment while the code under test can is a false failure with no bug behind it.
**Approved**: pending

**Decision**: Standard input is an empty, closed input, and the output is drained while `git` writes.
**Rationale**: Per the comments inside `rawGit(_:)` in `ReadOnlyGit.swift`, a read-only `git` never prompts, but an end-of-file guarantees it cannot block waiting on one; draining stops a large branch listing from filling the pipe buffer and deadlocking the child.
**Approved**: pending

**Decision**: Output that is not valid UTF-8 returns the empty string.
**Rationale**: Per the comment on the decode in `rawGit(_:)` in `ReadOnlyGit.swift`, git output is valid UTF-8, and a failable decode swallows anything else.
**Approved**: pending

