
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hub-mail-bridge-001 | provider-configured | `providerStatus` | configured, no client id |
| hub-mail-bridge-002 | admin-refused | `signIn`, `cancelSignIn`, `removeProvider`, `removeAccount`, `updateSettings`, `importOAuthClient` | each `.failure`; the mirror is unchanged |
| hub-mail-bridge-003 | accounts-from-connections, account-address | Connection `c1` with a SENT message from `Me <Me@X.com>`, connection `c2` with none | accounts `c1` (`me@x.com`) and `c2` (`c2`), active |
| hub-mail-bridge-004 | account-lookup | `listLabels` for `ME@x.com`, then for `nobody` | the labels of `c1`; then not found |
| hub-mail-bridge-005 | labels-mapped | Labels `INBOX` (system) and `Label_1` "Work" | `INBOX`, then `Label_1` named "Work" |
| hub-mail-bridge-006 | messages-filtered, label-resolution | Filter `labels: ["Work"]` over messages with and without `Label_1` | only the `Label_1` messages |
| hub-mail-bridge-007 | messages-filtered, any-labels-applied | `anyLabels: ["INBOX", "SENT"]` | messages carrying either, `appliedAnyLabels` true |
| hub-mail-bridge-008 | messages-filtered | `since`/`until` around one of three dates | only that message |
| hub-mail-bridge-009 | opaque-cursor | Three messages, limit 2, then the cursor back | 2 then 1, the second page's cursor nil |
| hub-mail-bridge-010 | opaque-cursor | Cursor `"zzz"` | `.failure("bad cursor")` |
| hub-mail-bridge-011 | query-refused | `query: "from:a"` | `.failure`; `query: "  "` lists normally |
| hub-mail-bridge-012 | label-resolution | `labels: ["Nope"]` | `.failure("unknown label: Nope")` |
| hub-mail-bridge-013 | bodies-on-request, message-mapping | `getMessage` by provider id for a message with only an HTML body | the hub row id, the provider id, the label names, the HTML read as text |
| hub-mail-bridge-014 | bodies-on-request | `listMessages` without `includeBodies` | no bodies |
| hub-mail-bridge-015 | thread-lookup | `getThread` by a message id of a three-message thread | the three, oldest first, `id` the thread id |
| hub-mail-bridge-016 | modify-through-hub, mirror-write | Add "Work", remove `INBOX` on one message | one write with the provider id, `["Label_1"]`, `["INBOX"]`; the answer and a re-read show the new labels; the row's sync version is unchanged |
| hub-mail-bridge-017 | modify-through-hub | Nothing to add or remove | no write; the message unchanged |
| hub-mail-bridge-018 | move-through-hub | Move two messages, one already in "Work" and out of INBOX, to "Work" | one write for both messages; results name `Work` added and `INBOX` removed for the other, nothing for the first |
| hub-mail-bridge-019 | move-through-hub | Move to INBOX from `["INBOX"]` | `.failure` |
| hub-mail-bridge-020 | write-failure | The writer throws | `.failure` with its message; the mirror unchanged |
| hub-mail-bridge-021 | sync-now | `syncNow(account: nil)` | the pull ran once; `.ok` |
| hub-mail-bridge-022 | client-transport | `MailClient` from `client` calls `accounts()` | the same accounts as `listAccounts` |
| hub-mail-bridge-023 | service-stable-client | A service never signed in calls `accounts()` | `MailClientError.remote(signedOutMessage)`; status `.signedOut` |
| hub-mail-bridge-024 | service-sign-in, service-status-callback | `signedIn()` over one pulled message, through a client taken before sign-in | status `.connected`, one `onChange`, accounts `c1` |
| hub-mail-bridge-025 | service-sign-out | `signedIn()` then `signedOut()` | status `.signedOut`; requests refused again; the store has no connections |
| hub-mail-bridge-026 | service-sign-in | `signedIn()` twice | `connect` called once |
| hub-mail-bridge-027 | service-sign-in, service-sign-out | `connect` throws | status `.failed`; requests refused; `signedOut()` returns to `.signedOut` |
| hub-mail-bridge-028 | service-follows-session | `follow(.restoring)`, sign in, `follow(.error)`, `follow(.signedOut)` | `.signedOut`, `.connected`, still `.connected` with accounts readable, `.signedOut` |
| hub-mail-bridge-029 | routed-client | A routed client over a direct stub and a connected service, switched between requests | the stub's empty accounts, then `c1` |
| hub-mail-bridge-030 | location-app-file | `HubMailLocation.app("AppName", defaults: suite)` | file name `hub-mail.db`, in a folder named `AppName`, directly under the user's Application Support directory |
| hub-mail-bridge-031 | location-device-id | `deviceId(defaults:)` twice on an empty suite, then `app("AppName", defaults:)` | one non-empty id, stored under `hub_mail_device_id`, returned each time and by `app` |
| hub-mail-bridge-032 | location-device-id | `""` stored under `custom`, then `deviceId(defaults:key: "custom")` | a new non-empty id, now stored under `custom` |
| hub-mail-bridge-033 | one-entry-point | Derived: a request whose handling throws inside the bridge (the writer throws), and a request for an unknown message | `respond(to:)` returns `.failure` for the first and `.notFound` for the second; neither throws |
| hub-mail-bridge-034 | message-lookup | Derived: `getMessage` by hub row id, then by provider id, then by `"zzz"` | the same message twice; then `.notFound("unknown message: zzz")` |
| hub-mail-bridge-035 | live-shares-session | Derived: `HubMailService.live` over a fake session store | the returned `HubAccount` and the service follow one `SessionController`; the database file does not exist until the first sign-in or sign-out, then its folder is created and it stays open |
| hub-mail-bridge-036 | live-at-location | Derived: `live(at: location)` and `live(databaseURL:deviceId:)` with the location's two values | both build the same session; `syncInterval` is 300 when not passed |
| hub-mail-bridge-038 | service-purge-left-over | One service signs in and pulls `c1`, then is dropped without signing out; a second service over the same database follows `.signedOut` | status `.signedOut`; the store has no connections |
| hub-mail-bridge-039 | service-sign-in-waits | While connected, `signedOut()` and `signedIn()` run concurrently, each with one message to pull | status `.connected`; accounts `c1` |
| hub-mail-bridge-040 | service-renews-refused-token | The first pull is refused with `.unauthorized`, the second returns message `m1` for `c1`; `refreshSession` returns true | `refreshSession` called once; accounts `c1`; status `.connected` |
| hub-mail-bridge-041 | service-renews-refused-token | The first pull is refused with `.unauthorized`, the second returns `m1` for `c1`; `refreshSession` returns false; `authRetryDelay` 50 ms | statuses `.connected`, `.failed(authRetryMessage)`, `.connected`; accounts `c1` |
| hub-mail-bridge-042 | accounts-from-connections | Connection `c1`; a bridge whose `lastSyncAt` answers `2026-11-16T10:00:00.000Z` | account `c1` has that `lastSyncAt` |
| hub-mail-bridge-043 | service-renews-refused-token | Sign in and pull `m1` for `c1`, then pull again with no changes | the account's `lastSyncAt` is set after the first pull and moves after the second |
| hub-mail-bridge-037 | location-value | Derived: two `HubMailLocation` values with the same `databaseURL` and `deviceId`, then one with a different `deviceId` | the first two compare equal; the third does not |

