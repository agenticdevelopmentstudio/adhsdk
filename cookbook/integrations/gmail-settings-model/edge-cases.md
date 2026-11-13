
- **Null and empty input, drafts**: Both drafts blank or whitespace-only. `saveClientDraft` MUST set the incomplete-form message and send nothing.
- **Null and empty input, secret suffix**: A configured client whose suffix is nil or empty. `maskedClientSecret` MUST return "Stored (hidden)".
- **Null and empty input, timestamp**: A nil or unparsable `lastSyncAt`. `lastSyncedText` MUST return "Never synced".
- **Null and empty input, selection**: No accounts. `selectedAccountId` MUST become nil after a reload.
- **Boundary values, sign-in tickets**: A model that has never signed in has no ticket, and `startedLatestSignIn` MUST be false.
- **Boundary values, secret mask**: The mask MUST be ten characters plus the suffix; the model does not compute the suffix length, the daemon sends it.
- **Boundary values, settings ranges**: The model does not clamp or validate `windowDays` or `pollIntervalMinutes`; it sends the settings it is given. Range limits live in `MailSyncSettings`.
- **Concurrent access, overlapping calls**: Calls may overlap; `busy` MUST count them and stay true until all finish. Each call's reload replaces `accounts` with the service's list.
- **Concurrent access, rapid settings changes**: Only one settings send per account runs at a time; later values replace the pending one (MUST).
- **Concurrent access, tracker**: The tracker is main-actor isolated, so tickets are issued serially (MUST).
- **Error states, action failure**: The first failure sets `errorMessage`; the reload still runs (MUST).
- **Error states, reload failure**: The reload failure sets `errorMessage` only when none is set (MUST). `accounts` and `provider` keep their previous values when the account read fails after the provider read; `provider` is assigned before the accounts are read, so it can be newer than `accounts`.
- **Error states, settings send failure**: Pending value dropped, chosen-value override released, reload restores the service's state (MUST). When several values were pending, the failure discards them all.
- **Error states, cancel failure**: Only `errorMessage` is set; no reload runs (MUST).
- **Error states, duplicate alerts**: An account error already alerted MUST NOT alert again until the account leaves the error state or its message changes.
- **Error states, removed account**: When an alerted account is removed, the next reload drops its record, because the alerted record is filtered to accounts still in error (MUST).
- **Offline or disconnected state**: The model has no connectivity handling of its own. A call that cannot reach the service fails like any other failure and shows `errorMessage`; there is no retry, backoff or timeout in this file. Whether the injected client retries is outside the file.

