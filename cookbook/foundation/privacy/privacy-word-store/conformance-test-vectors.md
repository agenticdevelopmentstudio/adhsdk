
The source has no test beside it that calls the store; the one test that mentions it, `TerminalPaneFamilyTests`, only constructs a `PrivacyWordsVault` around it. The vectors below are derived from the source and assume a keychain with the target entitlement.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| privacy-word-store-001 | load-empty-when-absent | New service and account with nothing saved; `load()`. | `[]`. |
| privacy-word-store-002 | save-replaces, single-item | `save([Pair(alias: "Acme", real: "Globex")])`, then `load()`. | An array equal to the one saved. |
| privacy-word-store-003 | save-replaces | `save` two pairs, then `save` one different pair, then `load()`. | Only the last pair. |
| privacy-word-store-004 | save-empty-removes | `save` one pair, then `save([])`, then `load()`. | `[]`; no item remains. |
| privacy-word-store-005 | save-empty-removes, delete-tolerates-missing | On an empty keychain, `save([])`. | Returns without error. |
| privacy-word-store-006 | unreadable | The item's data is bytes that are not a JSON array of pairs; `load()`. | Throws `StoreError.unreadable`. |
| privacy-word-store-007 | needs-authentication | Setup: write the item directly with `SecItemAdd` using an access control from `SecAccessControlCreateWithFlags(.userPresence)`. Then `load()` with no context. | Throws `StoreError.needsAuthentication`, no prompt shown. |
| privacy-word-store-008 | load-with-context | The same item; `load(context:)` with a context from `authenticate`. | The stored pairs. |
| privacy-word-store-009 | save-replaces | After vector 008, `save` the pairs, then `load()` with no context. | The pairs, with no error. |
| privacy-word-store-010 | keychain-error | Run without a `keychain-access-groups` entitlement or with an access group the app is not signed for; `save` one pair. | Throws `StoreError.keychain` carrying the failing status: the delete status when the delete already fails, otherwise the add status. |
| privacy-word-store-011 | authenticate-cannot-evaluate | A Mac with no usable owner authentication; `authenticate(reason:)`. | Throws `StoreError.authenticationFailed` with a non-empty message. |
| privacy-word-store-012 | error-descriptions | `StoreError.unreadable.errorDescription`. | `The privacy words in the keychain could not be read.` |
| privacy-word-store-013 | default-identity | `PrivacyWordStore(accessGroup: nil)`. | `service` is `com.agenticdevelopmentstudio.privacy-words`, `account` is `privacy-words`. |
| privacy-word-store-014 | access-group-injected | Two stores that differ only in `accessGroup`. | `load()` on the store with the second `accessGroup` returns `[]` after `save` on the first store (setup: save via store A, load via store B). |
| privacy-word-store-015 | authenticate-rejected | A Mac with owner authentication; `authenticate(reason:)` and the user cancels the system sheet. | Throws `StoreError.authenticationFailed` with the system's message, or `Authentication failed.` when none is given. |
