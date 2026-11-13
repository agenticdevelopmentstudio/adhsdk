
IntegrationError is the one error type that integration code throws or returns when an operation fails: settings validation, Google sign-in, token refresh, Keychain access, account and message lookup, and Gmail REST calls. It is a Swift enum with eleven cases, several carrying a string or a status code, and its doc comment states the design goal: "Every case reads as a sentence a person can act on." It conforms to `Error`, `Equatable`, `Sendable` and `LocalizedError`. It holds no state and performs no I/O. Callers branch on the case, and surface `errorDescription` to a person.

