
**Decision**: The handlers take a transport-neutral `HandlerRequest` and return a `HandlerResponse` instead of binding to an HTTP server type.
**Rationale**: The same routes are tested without a socket (the test suite calls `handle` directly) and mounted by roosterd under any prefix; the mount is the server's choice.
**Approved**: pending

**Decision**: `PUT agents/<id>` takes the id from the path and refuses a body whose `id` differs.
**Rationale**: A path is the resource identity; a mismatch is more likely a client bug than an intended rename, so it answers 400 rather than saving under either id.
**Approved**: pending

**Decision**: A non-UUID session id answers 404, not 400, and unmatched sub-paths answer 404 `No such route`.
**Rationale**: To a client, an id that cannot name a session names no session; the same 404 serves both, with the message saying which.
**Approved**: pending

**Decision**: `POST tools/<name>` accepts `arguments` as an object or as a string holding an object, and defaults `caller` to `external`.
**Rationale**: Command-line and tool-use clients often hold arguments as text; accepting both avoids a client re-encode. `external` marks a call that did not come from an agent turn, so a tool can distinguish it.
**Approved**: pending

**Decision**: A thrown `AgentToolError.invalidArguments` answers 400 `bad_request`, any other thrown `AgentToolError` answers 404 `not_found`, and any other thrown tool error answers 422 `unprocessable`.
**Rationale**: `invalidArguments` means the caller sent arguments that are not a JSON object, a client error, so 400. Any other `AgentToolError` (today only `unknownTool`) names a tool that does not exist, so 404. Any error the tool throws itself means it received a request it could not process, so 422. This is the `tools-call-tool-error` requirement.
**Approved**: pending

**Decision**: The tool list reports each tool's `permission` and `mutating` flags, and the call route does not enforce them.
**Rationale**: A caller sees the policy, but gating belongs to the host's turn loop; an external call through `POST tools/<name>` is a direct request and adds no prompt of its own. This is the `tools-call-no-permission-check` requirement.
**Approved**: pending

**Decision**: The tool-list `input_schema` falls back to an empty object when the stored schema text is not valid JSON.
**Rationale**: One tool with a bad schema must not make the whole list unavailable; the lossy projection is deliberate and silent in the reply.
**Approved**: pending

**Decision**: `ModelHandlers` never returns secret values and treats an absent `secrets` as "leave stored secrets alone".
**Rationale**: Secrets are write-only over this surface, so an edit of a name or role does not force the caller to resend a key it cannot read back.
**Approved**: pending

**Decision**: `AgentsJSON` is one public dialect (ISO-8601 dates, sorted keys, unescaped slashes) with a fresh coder per call.
**Rationale**: Stored rows, HTTP bodies and test fixtures read the same and a CLI client decodes identically; `JSONEncoder` and `JSONDecoder` are not `Sendable`, so sharing one instance across tasks would not compile under strict concurrency.
**Approved**: pending

**Decision**: `ModelHandlers` reuses `AgentHandlers.describe` for decoding errors, and this is recorded as technical debt.
**Rationale**: Both sets must word a malformed body the same way, so there is one description function. Today `ModelHandlers` depends on `AgentHandlers` for it, so the two handler sets are coupled. Fix path: move the description helper beside `HandlerError` (the shared tier both sets already use), keeping the `decoding-error-description` wording unchanged, so neither set depends on the other.
**Approved**: pending

**Decision**: The check-then-act race on `POST` to the model routes is accepted as known debt.
**Rationale**: The handler reads the registry for an existing id and then calls `upsert`, which is an insert-or-update; two concurrent creates of the same new id both pass the check, both answer 201, and the later write wins silently. The window is small on a loopback, single-user surface and a fix needs a registry change. Fix path: an atomic insert-if-absent in the registry that the handler maps to 409, which removes the separate read. Until then `models-create-check-order` only fixes the order of the two calls.
**Approved**: pending
