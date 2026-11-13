
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| client | `MailClient` | required | The service client every call goes through. |
| signIns | `GmailSignInTracker` | `GmailSignInTracker.shared` | The ticket counter shared by every settings model in the app. Tests pass their own. |
| clientIdDraft | `String` | empty | Client id field of the OAuth client form. |
| clientSecretDraft | `String` | empty | Client secret field of the OAuth client form. |
| selectedAccountId | `String?` | nil | The account the detail controls edit; settable by the view. |

