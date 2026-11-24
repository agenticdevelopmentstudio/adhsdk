
### Worker tokens

- **worker-token-name-required**: The create dialog MUST ask for a name, and MUST NOT submit a name that is
  blank after trimming.
- **worker-token-pool-checkbox**: The create dialog MUST offer a "Pool" checkbox, unchecked by default,
  whose description says that a pool token can claim AI steps of jobs from every product. The create
  MUST send `{ name, pool }`, with `pool` true only when the box is checked.
- **worker-token-scope-shown**: The tokens list MUST show whether each token is a pool token, read from
  the token's scopes (`ai-processing:pool`).
- **worker-token-reveal-once**: The created token MUST be shown once in a read-only field with a copy
  button, and closing the reveal MUST ask "Close without copying?" first.
- **worker-token-revoke-confirm**: Revoke MUST ask for confirmation and MUST say that every node using the
  token stops working.

### Dead jobs

- **dead-jobs-section**: `AiNodesPane` MUST show a "Dead jobs" section listing the queue's dead rows through
  `listDeadJobs`, which reads `GET /api/v1/processing/jobs?status=dead`, newest first. Each row shows
  its type, its ecosystem, its attempts, its last error and when it died.
- **dead-jobs-retry**: Each dead row MUST offer Retry, which calls `retryDeadJob(id)` (`POST
  /api/v1/processing/jobs/:id/retry`) and removes the row from the list once the call succeeds.
- **dead-jobs-retry-failure-shown**: A failed retry MUST be shown beside the list, and the row MUST stay.
- **dead-jobs-empty**: With no dead rows the section MUST say "No dead jobs."

### Topics

- **admin-topics-unchanged**: The operator admin topics MUST stay as they are. No "Jobs" or "Queue" topic
  is added, and none is renamed.

