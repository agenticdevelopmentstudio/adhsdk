
- **Null / empty input**: A `nil` `lastUser` while `.busy` MUST yield the signed-out controls (Login, and Signup when a URL exists) with controls disabled, not an empty signed-in layout. A `nil` message hides the line; an empty-string message is passed through as an empty string, not converted to `nil` (`message-passthrough`).
- **Boundary values**: Busy with a stale `lastUser` after the account has become signed out is not possible through `.signedOut`, which always drops `lastUser`; the stale value only survives while the state stays `.busy`. In `.signedIn`, a differing `lastUser` MUST be ignored in favour of the state's user.
- **Concurrent access**: The value is immutable and `Sendable`, so any number of readers are safe. Only the account-based initializer is main-actor isolated, so it is serialised with the account's own state changes.
- **Error states**: There is no failing path: the initializers do not throw or return an error. An error is shown only as the pass-through `message`; the display decides no wording and no severity.
- **Offline / disconnected state**: Not applicable: the display performs no network access; an unreachable server reaches it only as an account `message` or a state change.
- **Cancellation**: Not applicable: the display starts no asynchronous work, so there is nothing to cancel.
- **Stale caller history**: If the caller forgets to feed `shownUser` back as `lastUser`, a sign-out in progress renders as signed out (Login visible, disabled). The source documents this contract and does not guard against it (`caller-feeds-last-user`).
- **Busy with a signup URL absent**: Signed-out-like and busy with `hasSignupURL` false shows Login only.

