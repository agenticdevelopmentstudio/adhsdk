
**Decision**: A login with no stated expiry is classified `.unknown` (and counts as usable to `isAccessTokenUsable`) and is never refreshed pre-emptively.
**Rationale**: The source comment says refreshing on a guess spends a single-use refresh token "to learn what a failed request would have said for free"; the probe's own 401 answers the question with certainty.
**Approved**: pending

**Decision**: Having an `itemKey` is a precondition for spending a refresh token, checked before the refresh rather than after.
**Rationale**: The refresh token is single-use, so a rotation with no storage address would work for one round and then leave the app holding a voided pair. Refusing keeps the saved login alive, at the cost of reporting it `.expired` and unprobed.
**Approved**: pending

**Decision**: Credentials in a round are judged concurrently, and order is restored before folding.
**Rationale**: Each refresh has a 15-second ceiling and the app waits on the call with a ceiling of its own; four sequential refreshes could outlast that wait and the app would lose every rotation produced so far. Order is restored because the caller reads statuses positionally against what it pushed.
**Approved**: pending

**Decision**: The evaluator decides and refreshes, but never stores; it holds no timer and no state.
**Rationale**: macOS names the requesting process in a keychain permission dialog and only a process with a UI can answer it, so the app keeps custody. Refreshing only inside a call the app made guarantees the rotation reaches the one process that can persist it.
**Approved**: pending

**Decision**: Only `.spent` and an unrefreshed `.expired` drop a credential from `probeable`; `.rateLimited` and `.inconclusive` keep the original credential.
**Rationale**: A rate limit or an inconclusive answer says nothing about the login, and dropping it would blank the account's quota for a reason that is not about the account.
**Approved**: pending

**Decision**: `renew` ignores expiry and always spends the refresh token.
**Rationale**: It is called when a saved login is about to be installed as Claude Code's own, where the goal is a full access-token lifetime and proof the refresh token is alive; the caller is waiting on that one reply, so the rotation has a home.
**Approved**: pending

**Decision**: An error that is not a `ClaudeOAuthRefreshError` is reported `.inconclusive`, and in `renew` sets `tokenUntouched` false even when it is a transport error proving nothing was sent.
**Rationale**: Only `ClaudeTokenRefresher` can tell an unsent request from a lost reply, so anything else is treated as possibly spent. The quirk is that an injected refresher throwing a raw `URLError` never gets the `.unsent` treatment.
**Approved**: pending

**Decision**: Only a 401, or a 400 naming `invalid_grant`, is `.spent`; every other 4xx (403, 408, other 400s) is `.inconclusive`.
**Rationale**: Cloudflare's 403 "error code: 1010" never reaches the endpoint and a 408 is an edge timing out; reporting a good login dead sends the user through a browser login it never needed.
**Approved**: pending

**Decision**: Only six connection-level `URLError` codes count as never sent; a timeout or dropped connection is `.inconclusive`.
**Rationale**: A timeout proves nothing: the endpoint may have answered into the void and spent the token, so only failures that prove the request never left the machine may report the token untouched.
**Approved**: pending

**Decision**: A reply without `expires_in` is stamped with an 8-hour expiry instead of keeping the old one, and only fields the reply speaks to are folded in.
**Rationale**: Keeping an old expiry against a new token makes it read as stale, so every probe would refresh again and burn another single-use token. Carrying other fields forward keeps the login valid in Claude Code's own format, which this code does not fully know.
**Approved**: pending

**Decision**: A 2xx reply without a usable access token is caught right after parsing and reported `.inconclusive`, not passed deeper.
**Rationale**: By then the refresh token is spent; the source comment says a failure further along "would abandon whatever the response did carry and void the stored credential for nothing".
**Approved**: pending

**Decision**: Account attribution is published as a map of SHA-256(token) to account name in one shared file, written only by the app.
**Rationale**: The daemon and CLI cannot read keychain items, and a digest answers "whose token is this" without shipping a credential to a process that has no business holding one. One file means the daemon and the CLI cannot attribute one token to two accounts.
**Approved**: pending

**Decision**: `publish` merges into the existing file and keeps 8 fingerprints per account, re-stamping a digest seen again and letting the newest claim win a contested digest.
**Rationale**: A token minted an hour ago is still billing its account, so replacing would un-attribute live sessions; the cap stops the file growing one entry per rotation forever; a token cannot belong to two accounts, so keeping both would let lookup order decide.
**Approved**: pending

**Decision**: Lookups cache the parsed map keyed on the symlink-resolved file's modification date and size, and an empty token returns before any file access.
**Rationale**: The daemon asks on every hook event, so the steady state must be a dictionary lookup. `attributesOfItem` does not follow a final symlink, and a rewrite can land on the same coarse mtime, so size is in the key. Most hook events carry no token and must not pay for a read.
**Approved**: pending

**Decision**: Log lines name the account email with `privacy: .public`.
**Rationale**: The failure lines are what tells the owner which saved login to save again, and a redacted `<private>` line answers nothing on a single-user machine; the email is not a credential, and no token ever reaches a log line. The cost is that `no-pii-in-logs` is only partial.
**Approved**: pending

**Decision**: The parser skips entries it cannot use and ignores `version`.
**Rationale**: The source comment says a reader meets a newer file "by ignoring what it does not recognise, which is cheaper than a version negotiation between three targets that ship together anyway".
**Approved**: pending

