
- **Data collected**: `ClaudeCredentialDTO` carries a bearer token and, for an OAuth login, the whole `ClaudeOAuthCredential` with its refresh token. `accountEmail`, `oauthEmail`, `account` and `sessionId` identify the user and their sessions. `ClaudeVersionDTO.fieldsJson` is a captured status-line payload.
- **Storage**: The types store nothing. Per the source comments, the app keeps credentials in its keychain items and the daemon keeps pushed credentials in memory, keeping only `probeOnly` (no refresh token) after an evaluation.
- **Transmission**: The credential travels from the app to the daemon over the shared XPC listener, and a rotation travels back in the reply on the same connection; the usage records travel over XPC and the daemon's loopback HTTP.
- **Retention**: Not set by these types. The source states the daemon exposes no way to read a token back and holds a refresh token only for the evaluation that might spend it.
- **Token lifetimes**: The source comments put a bearer access token at eight hours and the default refresh margin at five minutes; both are the daemon's, and `refreshWithin` overrides the margin for one evaluation. A `claude setup-token` token never expires and never rotates, so its `oauth` is nil.
- **Revocation**: Not handled by these types; a failed probe surfaces as `errorText` (an expired token is the source's example).

