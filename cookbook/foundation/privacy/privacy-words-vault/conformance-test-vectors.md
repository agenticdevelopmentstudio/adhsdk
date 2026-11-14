
The source has no test of its own; `TerminalPaneFamilyTests` only constructs a vault (with a test service name) to build a pane family. The vectors below are derived from the source and need an injectable or test keychain item.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| privacy-words-vault-001 | filter-published, is-loaded | A new vault. | `filter` is nil and `isLoaded` is false (test: TerminalPaneFamilyTests builds a vault and only reads allowances). |
| privacy-words-vault-002 | load-empty | A new vault over an empty keychain; `load()`. | Returns true, `filter` has no pairs, `isLoaded` is true. |
| privacy-words-vault-003 | load-reads-store, save-normalises | The item holds pairs `a`/`b` and an empty-alias pair; `load()`. | Returns true and `filter.pairs` is only `a`/`b`. |
| privacy-words-vault-004 | load-silent | After vector 003, change the keychain item and call `load()` again. | Returns true and `filter` is unchanged from the first read. |
| privacy-words-vault-005 | load-needs-auth | The item is guarded by the old `userPresence` access control; `load()`. | Returns false, `filter` stays nil. |
| privacy-words-vault-006 | load-other-errors | The stored value is not valid JSON pairs; `load()`. | Throws `StoreError.unreadable`. |
| privacy-words-vault-007 | authenticate-upgrades | The old-guarded item; `authenticate(reason:)` and the owner succeeds. | `filter` holds the pairs, and a later silent `store.load()` succeeds without error. |
| privacy-words-vault-008 | authenticate-errors | The owner cancels the prompt; `authenticate(reason:)`. | Throws `authenticationFailed`; `filter` is unchanged. |
| privacy-words-vault-009 | authenticate-rereads | Loaded vault; another process rewrites the item; `authenticate` succeeds. | `filter` shows the new pairs. |
| privacy-words-vault-010 | upgrade-shared | The old-guarded item; start `loadUpgradingIfNeeded()` twice together. | One authentication prompt is shown and both calls complete. |
| privacy-words-vault-011 | save-authenticates | `save(pairs, reason:)` when authentication throws. | The error propagates and the store is not written. |
| privacy-words-vault-012 | save-applies, persist-announces | `save([Pair(alias: "a", real: "b")], reason:)` with success. | `filter.pairs` equals the pair and a notification named `<service>.<account>.changed` is posted with the process identifier as its object. |
| privacy-words-vault-013 | ignore-own-posts | A vault whose own save posts the notification. | Its `store.load` is not called again because of it. |
| privacy-words-vault-014 | reload-if-loaded | Two vaults on one item, both loaded; one saves. | The other's `filter` becomes the saved pairs. |
| privacy-words-vault-015 | reload-if-loaded | A vault that never loaded receives another process's notification. | `filter` stays nil and the store is not read. |
| privacy-words-vault-016 | notification-name | `changedNotification(for:)` with service `s` and account `a`. | `s.a.changed`. |

