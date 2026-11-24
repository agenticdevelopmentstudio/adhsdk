
The model has no pressed, focused or disabled states. Its observable states are these.

| State | Appearance change |
|-------|------------------|
| Default | `provider` is nil and `accounts` is empty until the first call finishes; `oauthClientText` reads "Checking for an OAuth client…". |
| Busy | `busy` is true while any call is in flight. |
| Signing in | `signingIn` is true while `addAccount` waits for the browser sign-in. |
| Not configured | `provider.configured` is false; `accounts` is empty; the client id and secret accessors return nil. |
| Configured | `provider.configured` is true; accounts are listed; the client id and masked secret are available. |
| Error | `errorMessage` is non-nil until the next call starts or `dismissError` runs. |
| Account error alert | `accountError` is non-nil until `dismissAccountError` runs. |
| Loading | Not applicable: the model has no separate loading flag; `busy` covers reloads. |

