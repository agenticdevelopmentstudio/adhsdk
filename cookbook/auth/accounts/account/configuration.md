
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `id` | `String` | supplied by the conformer | Identity; an account registry treats an id already present as a duplicate |
| `displayName` | `String` | supplied by the conformer | Title shown for the account |
| `summary` | `String` | supplied by the conformer | One line under the title while signed out |
| `signupURL` | `URL?` | supplied by the conformer | Where to sign up; `nil` hides Signup |
| `onChange` | `@MainActor () -> Void` | set by the conformer's initial value | Single observer slot, set by the accounts UI |
| `AccountUser.avatarURL` | `URL?` | none | Optional avatar image address |

