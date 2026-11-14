
- **Blank name**: A name of only whitespace has no words, so `initials` falls back to the email. Behavior: MUST.
- **Empty name and email**: `initials` is `"?"`. Behavior: MUST.
- **Name with more than two words**: Only the first two words contribute. Behavior: MUST.
- **Lowercase or non-letter first character**: The first character is uppercased as `String.uppercased()` does it; a digit or symbol stands as it is. Behavior: MUST.
- **Anchor object released**: `object` reads `nil`; `presentSignIn(from:)` receives an anchor with no object and the conformer decides what to do. Behavior: the weak read MUST return `nil`.
- **Repeated `restore()`**: Does nothing after the first call. Behavior: MUST.
- **Second observer assigned to `onChange`**: Replaces the first; the first stops being notified. Behavior: MUST.
- **Null and empty input**: `message` and `signupURL` are optional; `nil` means "none". Empty strings are accepted for every `String` field of `AccountUser` without validation.
- **Boundary values**: The only boundary is the two-word cap on `initials`, covered above.
- **Concurrent access**: Not applicable as a race: `Account` is `@MainActor`, so calls are serialised on the main actor; `AccountUser` and `AccountState` are immutable `Sendable` values.
- **Error states**: `signOut()` returns no error and the protocol carries no error channel other than `message`; how a conformer reports a failure is its own contract.
- **Offline or disconnected**: Not applicable to this file; it performs no I/O. A conformer's `restore()` may make a network call and owns the behavior when it fails.
- **Cancellation, timeout, retry**: The protocol declares none; `signOut()` has no cancellation hook and `restore()` has no timeout.

