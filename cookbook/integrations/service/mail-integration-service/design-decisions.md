
**Decision**: Cancel a pending sign-in when a new one starts, instead of refusing the new one.
**Rationale**: The source comment says a pending sign-in belongs to a client that gave up on it, such as a closed panel or a crashed app, and refusing would "lock Add Account out until the browser flow times out". Cancelling the old flow also closes its redirect listener so its abandoned tab cannot add an account.
**Approved**: pending

**Decision**: Fence provider removal with a generation counter and a removal counter, and re-check them after each await in sign-in.
**Rationale**: Per the comments, a sign-in under way when Gmail is removed would otherwise save a credential and bring the account back, and one starting during the removal would capture the already-bumped generation and pass every check. The cost is extra state and a revoke of the grant Google already issued.
**Approved**: pending

**Decision**: Store the credential before the connection row.
**Rationale**: The comment states this so a failed Keychain write leaves no active connection without a credential. The connection is then re-read after that await, so sync state written meanwhile is not rolled back.
**Approved**: pending

**Decision**: Keep last-attempt time in memory only and take the later of it and `lastSyncAt` for due-ness.
**Rationale**: The comment says a failing account then retries at the poll interval, not every tick. After a restart, due-ness falls back to `lastSyncAt`, so a failing account is retried at once; the source accepts that.
**Approved**: pending

**Decision**: Distinguish a locked or denied Keychain from "not configured".
**Rationale**: The comment says a read failure throws, "rather than reading as 'not configured' and sending the user to import a client they already have".
**Approved**: pending

**Decision**: Answer every failure as a `MailResponse` and mark unknown messages `notFound` inside `.failure`.
**Rationale**: A transport cannot carry a thrown error; `notFound` rides inside `.failure` so an older client still decodes it as a failure (`notFoundStillDecodesAsAFailureForAnOlderClient`).
**Approved**: pending

**Decision**: Page the mirror with a keyset cursor of internal date and id, not an offset.
**Rationale**: The comment says a sync or label change between pages moves rows in and out of the filter, and an offset would skip or repeat messages. Search cursors carry a `gmail:` prefix so each path refuses the other's cursor.
**Approved**: pending

**Decision**: Read Gmail before a move and write the same label change for every message.
**Rationale**: The comment says Gmail ignores removing a label a message lacks, and the local copy may be up to a sync interval old, so `added` and `removed` come from the fresh read and an already-moved message is not written.
**Approved**: pending

**Decision**: Treat a failed re-read after a label write as success logged `ok`, but still return a failure to the caller.
**Rationale**: The comment says the change is in Gmail so the action succeeded; the caller is told the labels applied and the refresh failed, so it does not repeat the write.
**Approved**: pending

**Decision**: Resolve ids missing from the mirror through Gmail without storing them.
**Rationale**: The mirror holds only the classes and window a connection syncs; a trashed, aged-out or never-synced message must still be readable. A write stores it only if it is mirrored.
**Approved**: pending

**Decision**: Quiesce a connection's sync (cancel and await) before changing its settings or removing it.
**Rationale**: A running sync would write back a cursor taken under the old settings, or recreate state for a removed account.
**Approved**: pending

**Decision**: Bound `stop` with a timeout rather than await syncs indefinitely.
**Rationale**: The comment says a sync stuck in a call that ignores cancellation must not hold up shutdown. The cost is that such a sync is left running when `stop` returns.
**Approved**: pending

**Decision**: Accept swallowed store failures on background paths for now, instead of logging or signalling them.
**Rationale**: `startDueSyncs` reads connections with `try?`, `performSync` skips when the connection read fails, and `record` writes status with `try?`. A store outage therefore appears as no sync and no status change, not as an error. Revisit when a store failure needs to be visible to a user; until then a port should keep the behavior or log it as a deliberate change.
**Approved**: pending

**Decision**: Accept that a Gmail profile failure during sign-in leaves the issued grant unrevoked, instead of revoking it.
**Rationale**: Only the provider-removed paths revoke the discarded credential; a profile error (`sign-in-profile-failure-no-revoke`) leaves the grant at Google. Revisit when sign-in failures are reported to users; until then a port must either match this or change it deliberately.
**Approved**: pending

