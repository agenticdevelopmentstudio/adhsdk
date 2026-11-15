
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `workspace` (every operation) | string (caller parameter, optional) | omitted → caller's own owner scope | Percent-encoded and appended as `?workspace=<slug>` by the shared query builder (omitted when empty); pins the operation to a workspace's owning principal instead of the caller's own scope. |
| body (create-group) | `{ name, slug, retentionDays? }` | none — required except `retentionDays` | Sent through the body-compaction helper as the `POST` body, with `retention_days` on the wire. |
| body (update-group) | all fields optional | none — required argument, fields individually optional | Sent through the body-compaction helper as the `POST` body to the item URL. |
| body (create-site) | `{ name, slug, groupId }`, all required | none — required | Sent verbatim (renamed to `site_group_id`) as the `POST` body; not passed through the body-compaction helper. |
| body (update-site) | all fields optional | none — required argument, fields individually optional | Sent through the body-compaction helper (renamed to `site_group_id`) as the `POST` body to the item URL. |
| `siteId` (list-endpoints, create-endpoint) | string (caller parameter, required) | none | Identifies the parent site; not sent on the list-endpoints operation (the /v1 collection has no site filter, so it only drives the client-side filter) and sent as the `site_id` body field on the create-endpoint operation. |
| body (create-endpoint) | `{ url, kind, expectedStatus?, checkIntervalSeconds?, isActive? }` | none — `url`/`kind` required, rest optional | Sent through the body-compaction helper as the `POST` body, with `site_id` added from the operation's own parameter. |
| body (update-endpoint) | all fields optional | none — required argument, fields individually optional | Sent through the body-compaction helper as the `POST` body to the item URL; carries no `site_id` field. |
| valid endpoint kinds | fixed set (`"http"`, `"tcp"`, `"icmp"`) | fixed | The declared set of valid `kind` values; not consulted by the create-endpoint/update-endpoint operations (`endpoint-kind-passthrough`). |
| the three route paths | fixed path strings | fixed | `/api/v1/monitoring/site_groups`, `/api/v1/monitoring/sites`, `/api/v1/monitoring/endpoints`; not injectable or configurable. |

