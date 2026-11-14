
| name | default | meaning |
|---|---|---|
| `fetchJson` | required | resolves a backend path to parsed JSON with the caller's token; rejects with an `Error` carrying a numeric `status` on HTTP failure |
| `pageSize` | 500 | the `limit` sent to `/sync/pull` (the hub clamps it to 1..1000) |

