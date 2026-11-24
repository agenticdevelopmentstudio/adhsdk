
- **Data collected**: The bearer token (`VERCEL_API_TOKEN`) and optional team id are credentials sent to Vercel; responses carry project names, ids and aliases.
- **Storage**: The module stores nothing; the token is supplied by the caller in `env`.
- **Transmission**: The token is sent only in the `Authorization` header to `https://api.vercel.com`. The query string carries `teamId` and caller parameters, not the token. `VercelHttpError` keeps the response body, which a caller could log.
- **Retention**: None.

