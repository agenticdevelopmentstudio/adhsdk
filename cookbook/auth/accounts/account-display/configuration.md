
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `state` | `AccountState` | none (required) | One of `restoring`, `signedOut`, `busy`, `signedIn(AccountUser)`. |
| `message` | `String?` | none (required) | The account's error or status line; `nil` hides it. |
| `hasSignupURL` | `Bool` | none (required) | Whether the account has a signup URL; false hides Signup. |
| `lastUser` | `AccountUser?` | none (required) | The previous render's `shownUser`, used only while busy. |

These are the inputs of the state initializer. The account-based initializer takes `account` and `lastUser` instead (see `account-initializer`), and the `restoringText` constant is listed under Localization. The display reads no environment variable or settings key.

