
Two files in the `Sessions` namespace define the wire contract between the `steno claude` command, the daemon and the menu-bar app for everything that can be asked or told about saved Claude accounts. Both import only `Foundation` and hold pure data: they perform no I/O, routing or validation, which belong to the daemon's and the app's handlers outside these files.

`ClaudeAccountRequestDTOs.swift` holds the request side:

- `ClaudeAccountOperation`, a `String`-backed enum naming the eight operations.
- `ClaudeAccountRequestDTO`, the one request envelope every operation travels in, which the daemon forwards to the app unchanged for a relayed operation.
- `ClaudeSavedAccountSummaryDTO`, one saved credential as the app lists it, with no secret in it.
- `ClaudeAccountResponseDTO`, the answer, in which each operation fills only the fields it is about.
- `ClaudeAccountRelay`, the two constants both ends compare on: the exact refusal sentence sent when no app is connected, and the app's bundle identifier.

`ClaudeAccountTokenDTOs.swift` holds the token side:

- `ClaudeTokenState`, the seven actionable states of one saved credential's token, with a short display `title` and an `isProbeable` verdict.
- `ClaudeAccountTokenStatusDTO`, one credential's token state "with no secret in it", the read surface for the CLI, the status line and the Usage window, with `counting(from:)` to recompute the countdown at read time.
- `ClaudeRotatedCredentialDTO`, a login the daemon just rotated, on its way back to the process that stores it.
- `ClaudeCredentialEvaluationDTO`, the daemon's answer when the app hands over its saved credentials: whether the set changed, and every rotated login.
- `ClaudeLoginRenewalDTO`, the daemon's answer to a request to renew one saved login before the app installs it as Claude Code's own.
- `ClaudeAccountsDTO`, the whole account picture: token statuses and quota readings in one document.

The source's doc comment states the split the request envelope serves: the daemon answers `usage` and `token` from what it already holds, so they work with the app shut, and every operation that has to touch a keychain item is relayed to the app, "which keeps custody of those items and runs the very code its own menus run."

The credential kind fields carry the raw value of Claude Credential Kind ([adhsdk.ingredient.foundation.claude-accounts.claude-credential-kind](cookbook:d457c4d4-005c-4fcb-a3a6-3e1680bcb561)), and `itemKey` carries that recipe's `"<kind>:<account>"` key spelling. Rotated and renewed logins carry a Claude OAuth Credential ([adhsdk.ingredient.foundation.claude-accounts.claude-o-auth-credential](cookbook:2b552bde-d0bd-425a-9e79-fc624b52f516)). Quota readings are `AccountQuotaReadingDTO` from Status Line DTOs ([adhsdk.ingredient.foundation.sessions.wire.status-line-dt-os](cookbook:94bac7a5-3fc6-463d-86d1-7c59350cd7cb)). The bundle identifier comes from Stenographer Instance ([adhsdk.ingredient.foundation.stenographer.stenographer-instance](cookbook:fe798f91-076e-41fc-9713-907b744c5539)).

