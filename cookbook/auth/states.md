
Not applicable as a visual-state table; this is a non-UI component. The session lifecycle is the transition table below. "Expired" is the signed-out state reached through a rejected refresh.

| State | Event | Next state | Store effect |
|-------|-------|-----------|--------------|
| signed out | `signIn` returns `.ok` | signed in | save session (token, kind, refresh token) |
| signed out | `signIn` returns `.accepted` | MFA pending | none |
| signed out | `signIn` returns `.unauthorized` | signed out | none; throws `invalidCredentials` |
| signed out | `login(email:password:)` succeeds | signed in | save `Credentials(kind: .jwt)` only |
| MFA pending | `completeMfa` or `completeMfaPasskey` returns `.ok` | signed in | save session |
| MFA pending | `completeMfa` returns `.unauthorized` | MFA pending | none; throws `invalidCredentials` |
| signed in | 401 on a non-exempt operation, JWT session with a refresh token | refreshing | none |
| refreshing | outcome `.refreshed` | signed in | save rotated session; retry once |
| refreshing | outcome `.rejected` | expired (signed out) | clear; call `onSessionExpired` |
| refreshing | outcome `.unavailable` | signed in | none; original 401 returned |
| signed in | `adopt(_:)` | signed in | replace credential; drop refresh token |
| signed in | `signOut()` | signed out | best-effort revoke, then clear |
| signed in | `logout()` | signed out | clear; no network call |
