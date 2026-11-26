
**Decision**: Secrets live outside the entry: the stored JSON holds only the secret field names, and values go to a `ModelSecretStore`.
**Rationale**: A SQLite file in Application Support is readable by anything running as the user and is copied by backups, while the Keychain is access-controlled; keeping values out of the file means a leaked or shared database exposes no credentials. The names let a resolver know which secrets to read without loading the plugin.
**Approved**: pending

**Decision**: Disabling an entry takes it out of service for role and id resolution alike.
**Rationale**: A user who disables an entry expects no feature to keep calling that provider, including a feature that pinned the entry by id; if only role lookup honoured the flag, a stored selector would silently bypass the user's choice (`disabledEntryDoesNotResolve`).
**Approved**: pending

**Decision**: An absent `secrets` argument keeps stored secrets, while a dictionary replaces them, with empty values removing a secret.
**Rationale**: This lets an edit that renames an entry leave the Keychain untouched, while a settings form that submits the full secret set can delete a secret by clearing its field (`secretUpdates`).
**Approved**: pending

**Decision**: Each `changes` stream observes its own signal instance, created by an injected factory.
**Rationale**: A signal holds one handler and a second `observe` replaces the first, so sharing one would let a new stream silence an older one. The stream buffers only the newest yield because consumers re-read the whole list, so queued yields would only repeat the same re-read.
**Approved**: pending

**Decision**: `test` returns a `ModelTestResult` for every failure instead of throwing.
**Rationale**: The result is shown to a person configuring an entry, so a failure is data (`isOK` false with a message), and latency is reported on failure too.
**Approved**: pending

**Decision**: Secret work goes before the row change, and the row's read and write share one transaction: `upsert` writes secrets first, `remove` deletes secrets first. `remove` throws before deleting the row and posts no signal when a secret removal fails; `upsert` with a failed stale removal still writes and signals, then throws.
**Rationale**: The Keychain cannot join a SQLite transaction, so the order decides what a failure leaves behind. Secrets first means a failed write leaves no row change and a failed delete leaves the entry naming the secret, so a failed removal never orphans a Keychain item. A failure partway through is undone by a rollback that reads each field's previous value before touching it and puts it back afterwards (`secret-write-rollback`), so a failed multi-secret `upsert` leaves no orphaned or half-replaced secrets. The rollback is best effort, because the Keychain can refuse it too; a refused restore is logged rather than thrown, so the caller sees the error that caused the failure. Reading the stored row inside the write transaction makes concurrent upserts last-writer-wins without losing `createdAt` (`concurrent-upsert`, `secret-removal-failure`). The stale-field set is read earlier, outside the transaction, because the removals must run before it opens (`upsert-stale-read`).
**Approved**: pending

**Decision**: The request value bag lists declared secrets even when blank, and scopes them to the named template.
**Rationale**: A blank-but-present key lets `buildRequest` tell "needs a key and it is blank" from "keyless", so it can report the missing key; scoping to the named template avoids a keyless template (Ollama) being rejected for a blank key it never needed.
**Approved**: pending

**Decision**: `list()` skips a row that fails to decode and logs it (`list-decode-failure`).
**Rationale**: One corrupt row must not take every picker and every role resolution down with it. The skipped row is logged at error level with its id, so the corruption is visible in the log and the id names the row to repair or remove; rows hold only secret names, and the log omits the JSON anyway. `get` of that id still throws, so a caller asking for that entry by id learns it is unreadable.
**Approved**: pending

**Decision**: `create` is a separate, atomic insert-if-absent, and a duplicate id throws `duplicate`.
**Rationale**: A check with `get` followed by `upsert` lets two concurrent creates of one id both succeed, the later silently replacing the earlier. `create` checks and inserts in one `IMMEDIATE` transaction, which takes SQLite's write lock before the check, so the check holds across processes as well as threads. The duplicate check runs before any secret is written, so a refused create cannot overwrite the existing entry's secrets; the secrets are written inside the transaction and rolled back if the insert or commit fails (`create-atomic`, `secret-write-rollback`).
**Approved**: pending

