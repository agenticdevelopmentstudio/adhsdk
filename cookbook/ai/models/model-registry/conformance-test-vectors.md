
Vectors marked (test) are asserted by `ModelRegistryTests.swift`; the others are
derived from the source and are not covered by a test there.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| MR-001 | list-order | (test `listsByName`) Upsert entries named `zeta`, `Alpha`, `beta`; call `list()` | Names in order `Alpha`, `beta`, `zeta` |
| MR-002 | list-order | Upsert two entries both named `Same` with ids `bbbbbbbb-0000-4000-8000-000000000001` and `aaaaaaaa-0000-4000-8000-000000000001`; call `list()` | The entry whose id string sorts lower comes first |
| MR-003 | entry-no-secret-values, upsert-secrets-empty-dropped, upsert-secret-fields | (test `secretsStayOutOfTheEntry`) Upsert with secrets `["apiKey":"sk-test","empty":""]` | Stored `secretFields == ["apiKey"]`; the store holds `sk-test` for `apiKey`; the entry's JSON does not contain `sk-test` |
| MR-004 | upsert-secrets-nil-keeps | (test `secretUpdates`) Upsert with `["apiKey":"one","orgId":"org"]`, rename the entry, upsert with secrets absent | Stored `secretFields == ["apiKey","orgId"]` |
| MR-005 | upsert-secrets-replace | (test `secretUpdates`) Then upsert with `["apiKey":"two"]` | `secretFields == ["apiKey"]`; store value for `apiKey` is `two`; value for `orgId` is absent |
| MR-006 | upsert-timestamps | (test `keepsCreatedAt`) Upsert an entry with `createdAt` 1000 s after 1970, then upsert it again with `createdAt` set to now | Stored `createdAt` is still the first value; `updatedAt` is later than it |
| MR-007 | remove-deletes, remove-absent-ok | (test `removeClearsSecrets`) Upsert with `["apiKey":"sk"]`, remove, remove again | `get` returns none; the secret store holds 0 items; the second remove does not throw |
| MR-008 | upsert-validation | (test `validates`) Upsert entries with name `"  "`, with an empty plugin identifier, and with an empty template id | Each throws `ModelRegistryError` (`invalidEntry`) |
| MR-009 | upsert-validation | Upsert an entry named with only a newline | Accepted: only spaces and tabs are trimmed, so the name is not empty |
| MR-010 | resolve-role | (test `resolvesRole`) Entry `A` holds `fast` but is disabled; entry `B` holds `fast` and `cheap`; resolve role `fast`, then `smart` | `fast` gives `B`; `smart` gives none |
| MR-011 | resolve-selector-role, resolve-selector-config, resolve-secrets | (test `resolvesSelector`) Entry with model `fake-native`, role `smart`, secret `apiKey=sk`; resolve `.role("smart")`, `.config(id, "fake-prompted")`, `.config(id, "")`, `.config(random id, nil)` | Model `fake-native` with secrets `["apiKey":"sk"]`; model `fake-prompted`; model `fake-native`; none |
| MR-012 | resolve-disabled | (test `disabledEntryDoesNotResolve`) Upsert a disabled entry; resolve `.config(id, nil)` | None |
| MR-013 | request-values, effective-model-order | (test `requestValues`) Entry fields `["authMode":"key"]`, resolved with model absent and secrets `["apiKey":"sk"]`, descriptor with template default `baseURL` | Model is the template's default model; `baseURL` is the template default; `authMode` is `key`; `apiKey` is `sk`; `model` equals the chosen model |
| MR-014 | request-secret-scope | Request values for a template whose field list has no `apiKey` secret, with the descriptor's shared list declaring one | The bag has no `apiKey` key |
| MR-015 | plugins-listing, plugin-summary-template | (test `listsPlugins`) Registry whose runtime discovers one fake descriptor | One summary with that identifier; its first template lists 2 models |
| MR-016 | test-round-trip, test-success | (test `testsAModel`) Stream yields text delta ` OK\n` then end | `isOK` true; `message == "OK"`; `latencyMs >= 0`; the built request had `maxTokens == 64` |
| MR-017 | test-empty-reply, test-never-throws | (test `testFailures`, which asserts `isOK` only) Stream yields only an end event; then call `test` with a random id | First: `isOK` false with message `Empty reply from the model` (message from the source, not asserted); second: `isOK` false with message `No model entry with id <uuid>` (likewise) |
| MR-018 | upsert-signals, remove-signals, changes-stream | (test `postsChanges`) Create a `changes` stream, upsert, remove | The signal posted exactly 2 times; the stream yields |
| MR-019 | changes-coalesce | Upsert three entries before reading a `changes` stream | The stream holds one pending yield, not three |
| MR-020 | test-result-wire | (test `testResultWire`) Encode `ModelTestResult(isOK: true, latencyMs: 12, message: "OK")` | JSON contains `"ok":true`; decoding it gives `isOK` true |
| MR-021 | selector-wire-form | (test `selectorWire`) Round-trip `.role("fast")`, `.config(id, "m")`, `.config(id, nil)`; decode `{"type":"role","role":"smart"}` | Each round-trips equal; the JSON decodes to `.role("smart")` |
| MR-022 | selector-decoding | Decode `{"type":"other"}` as a selector | Decoding throws with description `Unknown model selector type 'other'` |
| MR-023 | entry-minimal-decode | (test `minimalEntryDecodes`) Decode `{"configuration":{"id":"<uuid>","name":"Min","pluginIdentifier":"p","templateId":"t"}}` | `id` equals the uuid; `enabled` true; `roles` and `secretFields` empty |
| MR-024 | entry-effective-model | Entry with `model` the empty string, then `model` `"m"`, then `model` absent | `effectiveModel` is absent, `"m"`, absent |
| MR-025 | upsert-secret-write-failure, secret-store-write-failure | Upsert with a secret whose store `set` throws `writeFailed(field: "apiKey")` | Upsert throws it with description `Could not store the secret 'apiKey' in the Keychain`; no row is written |
| MR-026 | list-models-errors | Call `listModels` with an unknown id; with an entry whose plugin is not discovered; with an entry whose template id is not in the plugin | Throws `notFound`, `pluginNotInstalled`, `unknownTemplate` respectively |
| MR-027 | list-models-source | Entry whose provider has no live source (or whose load answers nothing) | Returns the template's `models` list |
| MR-028 | secret-store-announce | `SharedGroupModelSecrets` with a notification name; `set`, then `remove` | Notification posted after each; with a nil name nothing is posted |
| MR-029 | store-migration | Open the registry twice on the same file | Second open succeeds and keeps the stored rows |
| MR-030 | list-decode-failure | Insert a row whose `json` is not a valid entry; call `list()` | `list()` throws |
| MR-031 | store-location | Read `ModelRegistry.defaultStoreURL` | Ends with `Library/Application Support/com.agenticdevelopmentstudio.models/models.sqlite` under the home directory |
| MR-032 | store-directory-created | Open at a store URL whose parent directory is absent | The directory is created and the file opened |
| MR-033 | changes-per-stream-observer | Create two `changes` streams, then write | Each stream yields; ending one does not stop the other |
| MR-034 | remove-absent-ok | Remove an id with no row, with a signal double | No throw; the signal posted once |
| MR-035 | upsert-replaces-row | Upsert an id, then upsert the same id with a new name | `list()` returns one entry with the new name |
| MR-036 | secret-removal-failure, upsert-secret-fields | (test `secretRemovalFailure`) Upsert with `apiKey`, `orgId`; make removing `orgId` fail; upsert with `["apiKey":"two"]`, then remove | The upsert throws `removeFailed(field: "orgId")` and the entry keeps `["apiKey","orgId"]`; the remove throws the same and the entry is still stored |
| MR-037 | concurrent-upsert, upsert-stale-read | Upsert id X with secrets `["a":"1","b":"1"]`; then run call 1 (`["a":"1","b":"1"]`) against a store double whose `set` for `a` runs call 2 (`["a":"2","b":"2"]`) to completion first | Both calls complete; the row is call 1's (last writer); `createdAt` is the first stored value; each of `a` and `b` holds the value of one of the two calls (a mix is allowed); `secretFields == ["a","b"]` |
| MR-038 | upsert-stale-read, concurrent-upsert | Entry X stored with `secretFields == ["a"]`; start `upsert(X, ["b":"1"])` and, after its stale read but before its transaction, let a second call upsert X with `["a":"1","c":"1"]` | The first call removes `a` from the store (decided from its earlier read); the final row names the first call's fields; `c` stays in the store but unnamed in `secretFields` |
| MR-039 | get-by-id | Upsert an entry; call `get` with its id, then with a random id | The first returns the entry; the second returns none and does not throw |
| MR-040 | entry-json-format | Upsert an entry whose `updatedAt` is a known date and whose field value holds `a/b`; read the row's `json` | Dates are ISO-8601 strings, keys are sorted, and `a/b` is not escaped as `a\/b` |
| MR-041 | entry-row-shape | Upsert an entry; read the row directly | One row whose `id` is the id string, whose `json` decodes to the whole entry, and whose `updated_at` equals `updatedAt` as seconds since 1970 |
| MR-042 | list-models-inputs | `listModels` for an entry with `baseURL` `https://x` and secret `apiKey=sk`, then for one with neither, using a recording model manager | The first call receives plugin identifier, template, `https://x` and `sk`; the second receives absent `baseURL` and absent `apiKey` |
| MR-043 | list-models-main-actor | `listModels` with a model source whose resolution and load record the thread | Resolution runs on the main actor; the load does not |
| MR-044 | test-ignores-other-events | `test` with a stream of a thinking delta, a tool use, a usage event, text delta `OK`, end, then text delta `LATE` | `isOK` true with `message == "OK"`; `LATE` is never read |
| MR-045 | secret-store-keychain-choice | Create `SharedGroupModelSecrets` with no keychain in a process with the shared-group entitlement, then in one without | The first uses the shared Keychain group; the second uses the same service in the process's own Keychain |
| MR-046 | request-secret-scope | Request values for an entry whose template id no longer resolves in the descriptor, the descriptor's shared list declaring `apiKey` | The bag holds `apiKey` (the descriptor's shared list), blank when the secret is missing |
| MR-047 | resolve-role | Entries holding `Fast` and `fast`, both enabled; resolve role `fast`, then `FAST` | `fast` gives the entry holding `fast`; `FAST` gives none (exact string equality) |
| MR-048 | resolve-role, list-decode-failure | Insert a row whose `json` is invalid, plus a valid enabled entry holding `fast`; resolve role `fast` | `resolve(role:)` throws, as does `resolve(.role("fast"))`; `get` of the valid entry still succeeds |
| MR-049 | secret-write-orphan, upsert-secret-write-failure | Upsert a new entry with secrets `a`, `b` where the store's `set` for the second written field throws | The upsert throws; no row exists; the first written value remains in the store (no rollback) |
| MR-050 | test-round-trip, effective-model-order | `test` for entries with model `m`, then model absent with a template default, then model absent with no template default | The request model is `m`, the template's default model, the descriptor's default model respectively |

