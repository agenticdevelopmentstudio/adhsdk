
- **Data collected**: `Message.text`/`attachments` (arbitrary caller- and
  backend-supplied content), participant identifiers
  (`Participant.id`/`senderID`/`requesterID`), and permission-grant history
  (a `PermissionDecision` keyed by `permission.id` plus `requesterID` in
  `InMemoryPermissionStore`). None of these three files treats any of it as a
  credential or token, but message text and attachments can carry arbitrary
  content a user chooses to type or attach.
- **Storage**: Entirely in-memory — plain class fields in `DefaultOrchestrator`
  and a `Map` in `InMemoryPermissionStore` — for the lifetime of the owning
  instance; nothing in these three files writes to disk, `localStorage`, or a
  database.
- **Transmission**: None directly. These three files perform no network I/O
  themselves; all transmission is delegated to whichever concrete `Backend`
  implementation is injected (out of scope for this recipe). `ScriptedBackend`
  performs no transmission at all — it only records calls in memory.
- **Retention**: For the lifetime of the instance only. Constructing a new
  `DefaultOrchestrator`/`InMemoryPermissionStore` (or restarting the process)
  discards all of it; there is no expiry or revoke path for an already
  remembered `allowAlways`/`denyAlways` decision short of that (see
  store-has-no-revoke-operation).

