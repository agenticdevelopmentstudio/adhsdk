
Shape and ordering

- **value-type**: `AccountDisplay` MUST be an immutable value type (`struct` with only `let` properties) that is `Sendable` and `Equatable`.
- **pure-computation**: Every property MUST be computed once at construction from the inputs alone; constructing with the same inputs MUST yield an equal value.
- **state-initializer**: The display MUST be constructible from `state: AccountState`, `message: String?`, `hasSignupURL: Bool` and `lastUser: AccountUser?`, where `lastUser` is the previous render's `shownUser`.
- **account-initializer**: A second initializer taking `account: any Account` and `lastUser: AccountUser?` MUST be isolated to the main actor and MUST delegate to the state initializer with `account.state`, `account.message`, and `hasSignupURL` true exactly when `account.signupURL` is not `nil`.

Which user is shown

- **shown-user-signed-in**: When the state is `.signedIn(user)`, `shownUser` MUST be that user, regardless of `lastUser`.
- **shown-user-busy**: When the state is `.busy`, `shownUser` MUST be `lastUser` (which may be `nil`), so that signing out keeps showing who is signing out rather than flashing the signed-out controls.
- **shown-user-otherwise**: In every other state (`.restoring`, `.signedOut`), `shownUser` MUST be `nil` and `lastUser` MUST be ignored.

Status line and spinner

- **status-text**: `showsStatusText` MUST be true exactly when the state is `.restoring`.
- **restoring-text**: The status line text exposed as `AccountDisplay.restoringText` MUST be the string `Checking sign-in…` (with a single ellipsis character).
- **spinner**: `showsSpinner` MUST be true exactly when the state is `.restoring` or `.busy`.

Controls

- **login-visibility**: `showsLogin` MUST be true exactly when the display is signed-out-like: the state is `.signedOut`, or the state is `.busy` and `shownUser` is `nil`.
- **signup-visibility**: `showsSignup` MUST be true exactly when the display is signed-out-like and `hasSignupURL` is true.
- **logout-visibility**: `showsLogout` MUST be true exactly when `shownUser` is not `nil`.
- **no-controls-while-restoring**: While the state is `.restoring`, `showsLogin`, `showsSignup` and `showsLogout` MUST all be false.
- **controls-enabled**: `controlsEnabled` MUST be false exactly when the state is `.busy`, and true in every other state.
- **enabled-is-independent-of-visibility**: `controlsEnabled` MUST be true while the state is `.restoring` even though no button is visible then; it reflects only whether the state is busy.

Message

- **message-passthrough**: `message` MUST be the `message` input unchanged for every state; `nil` means the line is hidden. The display neither trims, rewrites nor suppresses it, including an empty string.

Side effects

- **no-side-effects**: Constructing an `AccountDisplay` MUST NOT start sign-in, sign-out or restore work, and MUST NOT write to any store or the network. The account-based initializer only reads `state`, `message` and `signupURL` from the account.

Ordering and concurrency

- **actor-isolation**: The state initializer is nonisolated and callable from any context; only the account-based initializer is `@MainActor`, because `Account` is a main-actor protocol. The value itself is `Sendable` and may cross actors.
- **caller-feeds-last-user**: The caller MUST pass the previous render's `shownUser` back as `lastUser` on the next render; the display keeps no history of its own, so a caller that passes `nil` while busy gets the signed-out controls.

