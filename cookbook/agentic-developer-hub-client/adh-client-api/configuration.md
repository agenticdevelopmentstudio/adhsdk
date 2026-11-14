
`api` has no parameters of its own; everything comes from the `ADHClient` it is read from.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `transport` | `APITransport` | none on the initializers; the factories supply `.direct()`, `.daemon()` or the `TransportResolver` choice | Supplies `serverURL` and the `ClientTransport` the `Client` is built from. |
| `middlewares` | array of `ClientMiddleware` | one `AuthenticationMiddleware` (bearer-only init) or one `SessionRefreshMiddleware` (session init) | The chain every request on `api` runs through. |

