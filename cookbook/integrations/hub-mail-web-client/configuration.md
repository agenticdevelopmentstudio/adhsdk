
| name | default | meaning |
|---|---|---|
| `fetchJson` | required | resolves a backend path to parsed JSON with the caller's token; rejects with an `Error` carrying a numeric `status` on HTTP failure |
| `pageSize` | 500 | the `limit` sent to `/v1/sync/pull` (the hub clamps it to 1..1000) |

Wire mapping from a `/v1/sync/pull` message row's `data` columns to the fields a message carries:

| column | field |
|---|---|
| `connection_id` | `account` (ties the row to its connection) |
| `thread_id` | `threadId` |
| `from_address` | `from` |
| `to_addresses` | `to` |
| `cc_addresses` | `cc` |
| `subject`, `snippet` | `subject`, `snippet` |
| `internal_date` | `date` |
| `label_ids` | `labelIds` |
| `body_text`, `body_html` | `bodyText`, `bodyHtml` (detail only) |
