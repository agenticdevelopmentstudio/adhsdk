
**Decision**: Use the user's `gh` and its login rather than a token of the app's own.
**Rationale**: The user already trusts `gh` with their GitHub account; holding a second credential would add storage, refresh and revocation the app has no reason to own.
**Approved**: pending

**Decision**: Map errors by standard error text and exit status.
**Rationale**: `gh` reports a missing login and a non-GitHub repository with exit status 1 or 4 and a sentence, not a distinct code; matching a few stable phrases case-insensitively separates the two outcomes the UI hides from the ones it reports.
**Approved**: pending

**Decision**: Record `gh` calls in the git command log.
**Rationale**: The Git window's Command Log is where a user asks "what did the app run"; a second log for `gh` would split the answer.
**Approved**: pending

**Decision**: The runner is injected.
**Rationale**: Tests must never reach the network or a real GitHub; a stub runner with recorded `--json` output exercises arguments, environment, decoding and error mapping without spawning anything.
**Approved**: pending

