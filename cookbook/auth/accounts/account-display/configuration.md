
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `state` | `AccountState` | none (required) | One of `restoring`, `signedOut`, `busy`, `signedIn(AccountUser)`. |
| `message` | `String?` | none (required) | The account's error or status line; `nil` hides it. |
| `hasSignupURL` | `Bool` | none (required) | Whether the account has a signup URL; false hides Signup. |
| `lastUser` | `AccountUser?` | none (required) | The previous render's `shownUser`, used only while busy. |
| `account` | `any Account` | none (required) | Alternative input to the account-based initializer, which reads `state`, `message` and `signupURL`. |
| `restoringText` | `static let String` | `Checking sign-in…` | The status line text for `.restoring`. |

The display reads no environment variable or settings key.

