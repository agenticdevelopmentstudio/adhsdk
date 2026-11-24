
- **Data collected**: A Google access token, refresh token and token expiry per connected account, plus the OAuth client id and secret passed in by the caller. The `email` and `openid` scopes are requested, but this component reads no profile data.
- **Storage**: Each credential is persisted as JSON through `SecretStoring` (the Keychain) under a per-connection key. A credential the Keychain refused to save is held in actor memory only, until a save succeeds, a `store` or `forget`, or process exit.
- **Transmission**: Tokens and the client secret are sent only to Google, over HTTPS: the authorization, token and revoke endpoints listed under Behavioral Requirements. The loopback redirect carries the authorization code over plain HTTP on 127.0.0.1 only. The refresh token is the only value sent to revoke.
- **Retention**: A credential stays in the Keychain until `forget` removes it; `revoke` ends the grant at Google but does not delete the local copy. Access tokens last as long as Google reports (default 3600 seconds) and are refreshed 60 seconds before expiry. Revocation by the user surfaces as `invalid_grant`, then `revoked`.
- **Log hygiene**: The logger records the connection id (marked public) and the error's description; none of the logged values are tokens or secrets.

