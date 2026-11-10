
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `baseURL` | `URL` | `DaemonContract.backendURL` | Base URL the two endpoint paths are appended to. Caller-overridable; tests override it implicitly by installing `StubURLProtocol` on the `session` instead. |
| `credentials` | `any CredentialProvider` | none (required) | Supplies the bearer token, read fresh via `currentCredentials()` on every request. |
| `session` | `URLSession` | `.shared` | The `URLSession` `perform` issues requests through. |
| `cursor` (pull parameter) | `String?` | `nil` | Opaque, server-issued sync cursor; omitted from the query when `nil`. |
| `limit` (pull parameter) | `Int` | none (required) | Requested page size for `/sync/pull`; forwarded to the server without local validation. |
| `body` (push parameter) | `Data` | none (required) | Pre-encoded `SyncPushRequest` JSON; forwarded to the server without local validation. |

No environment variables or persisted settings keys are read by this source.

