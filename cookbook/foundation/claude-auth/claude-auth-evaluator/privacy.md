
- **Data collected**: Bearer secrets supplied by the caller (OAuth access tokens, single-use refresh tokens, setup tokens), plus the account email, keychain item key and subscription metadata riding in each login. `AccountFingerprints` handles tokens only long enough to hash them, and stores account names.
- **Storage**: The evaluator and refresher store nothing and keep no state between calls; custody of the stored login stays with the app. The fingerprints file stores SHA-256 digests of tokens and account names (emails) with a `seen` time, in the Stenographer support directory, mode 0600 (see the open question on `publish-permissions-failure`). A digest does not reverse to the token. The read cache keeps the parsed map in process memory.
- **Transmission**: `ClaudeTokenRefresher.refresh` sends an expired login's refresh token and the client id over HTTPS to Claude Code's token endpoint. Rotated logins leave only in `Outcome.rotated` or `Sessions.ClaudeLoginRenewalDTO.oauth`, to the caller that supplied them. The fingerprints file never leaves the machine.
- **Retention**: Secrets are not retained after a call returns. The fingerprints file keeps the 8 most recently seen fingerprints per account indefinitely; no entry expires by age and no account is ever purged.

### Security

- **sensitive-data**: The access token, the refresh token and the rotated pair are the sensitive data; the refresh token is the most sensitive because it mints further credentials and is single-use.
- **status-carries-no-secret**: `Outcome.statuses` and every value from `status(...)` MUST carry no token, so they can be served to any reader.
- **rotation-return-path**: A rotated pair MUST leave the evaluator only as a return value of the call that produced it.
- **no-unstorable-rotation**: The evaluator MUST NOT spend a refresh token for a credential with no `itemKey`, because a rotation with no storage address destroys the saved login.
- **token-lifetime**: An access token is treated as expired 300 seconds (or `refreshWithin`, when larger) before its stated expiry; a login with no stated expiry is never refreshed pre-emptively. A fresh token gets the reply's `expires_in` or 8 hours. Refresh-token lifetime is recorded in `refreshTokenExpiresAt` and reported in `refreshExpiresAt` but decides nothing.
- **revocation-handling**: A `.spent` refusal (HTTP 401, or 400 with `invalid_grant`) MUST be reported as `.spent` and the credential MUST be dropped from `probeable`; nothing retries it.
- **transport**: The token exchange MUST use the HTTPS `tokenURL`; the refresh token travels only in the request body, never in the URL.
- **fingerprints-carry-no-secret**: The fingerprints file MUST hold digests, never tokens; this rests on the caller passing fingerprints to `publish` (publish-digest-keys).
- **tokens-not-logged**: Log lines MUST NOT include any token; they include the account email (as public) and the short reason only.

