
The operator's AI processing panes in `@adh-sdk/adh-admin`: `AiNodesPane` (the hub's AI nodes, their
logs and settings) and the `WorkerTokens` section it mounts, over the admin-gated
`/api/v1/processing` client in `api/processing.ts`. This ingredient records the parts phase 9 (Jobs)
changes, written before that code:

- The worker token create form gains a **Pool** checkbox. A pool token also carries the
  `ai-processing:pool` scope, which lets a hub node claim AI steps of jobs ([adhsdk.ingredient.adh.hub.jobs](cookbook:0bcb370d-a44f-48a8-a313-0266c2f86e51)) in every
  ecosystem.
- `AiNodesPane` gains a **Dead jobs** section that lists the queue's dead rows, newest first, each with
  Retry.

The operator admin topics are unchanged. There is no operator "Jobs" topic today, so nothing is
relabelled.

