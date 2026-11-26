
### Storage

- **store-location**: Opening the registry with no explicit store location
  MUST use `~/Library/Application Support/com.agenticdevelopmentstudio.models/models.sqlite`
  (`ModelRegistry.defaultStoreURL`), so every process of the user opens the same file.
- **store-directory-created**: Opening the registry at a store location MUST
  create the location's parent directory, with intermediate directories, when it
  is absent, and MUST throw the file system's error when the directory cannot be created.
- **store-migration**: Opening the registry MUST run the migration `models-v1`,
  which creates the table `model_entries` with columns `id` (text primary key,
  not null), `json` (text, not null) and `updated_at` (real); a registry opened
  on an already-migrated file MUST NOT recreate or alter the table.
- **entry-row-shape**: The registry MUST store each entry as one row keyed by
  the entry's `id` string, whose `json` column holds the whole `ModelEntry` and
  whose `updated_at` column holds `updatedAt` as seconds since 1970.
- **entry-json-format**: The registry MUST encode an entry's JSON with ISO-8601
  dates, sorted keys and unescaped slashes (`AgentsJSON`), and MUST decode it
  with ISO-8601 dates.
- **entry-no-secret-values**: The stored JSON of an entry MUST NOT contain a
  secret value; it MUST carry only the field names in `secretFields`.

### Data shapes

- **entry-identity**: A `ModelEntry` MUST take its `id` from
  `configuration.id`; the same id is the Keychain account prefix of the
  entry's secrets (through `AIProviderConfigKeys.fieldKey(config:field:)`).
- **entry-fields**: A `ModelEntry` MUST carry `configuration` (id, name,
  pluginIdentifier, templateId), `fields` (non-secret values such as `baseURL`
  and `authMode`), `model` (optional default model id), `roles`, `enabled`,
  `origin` (optional bundle id of the importing app), `secretFields`,
  `createdAt` and `updatedAt`.
- **entry-minimal-decode**: Decoding a `ModelEntry` MUST require only
  `configuration`; a missing `fields` MUST decode to an empty dictionary,
  `model` and `origin` to absent, `roles` and `secretFields` to empty lists,
  `enabled` to `true`, and `createdAt` and `updatedAt` to the decode time.
- **entry-effective-model**: `ModelEntry.effectiveModel` MUST be the entry's
  `model` when it is non-empty, and absent when `model` is absent or the empty
  string, which means "use the template's default".
- **selector-wire-form**: A `ModelSelector` MUST encode to a flat JSON object:
  `{"type":"role","role":"<role>"}` or `{"type":"config","id":"<uuid>","model":"<model>"}`
  with `model` omitted when the selector has no override.
- **selector-decoding**: Decoding a `ModelSelector` MUST fail with a data
  corrupted decoding error whose description is `Unknown model selector type '<type>'`
  when `type` is neither `role` nor `config`.
- **test-result-wire**: A `ModelTestResult` MUST encode its `isOK` property under
  the JSON key `ok`, and `latencyMs` and `message` under their own names.
- **resolved-model-not-serialized**: `ResolvedModel` MUST be an in-memory value
  (entry, model, secrets) and MUST NOT be encoded or stored.

### Listing and lookup

- **list-order**: `list()` MUST return every stored entry ordered by
  configuration name using a case-insensitive, locale-aware comparison, and MUST
  break ties between equal names by ascending id string.
- **list-decode-failure**: `list()` MUST throw when any stored row fails to
  decode; it MUST NOT skip the row.
- **get-by-id**: `get(_:)` MUST return the entry stored under the id, and MUST
  return no entry (not an error) when no row has that id.

### Writing

- **upsert-validation**: `upsert` MUST throw `ModelRegistryError.invalidEntry`
  with the message `A model entry needs a name` when the configuration name is
  empty after trimming spaces and tabs, `A model entry needs a plugin identifier`
  when `pluginIdentifier` is empty, and `A model entry needs a template id` when
  `templateId` is empty, and MUST write nothing (no row, no secret, no signal) in
  that case.
- **upsert-replaces-row**: `upsert` MUST insert the entry when no row has its id
  and MUST replace the stored JSON and `updated_at` of the row when one does.
- **upsert-timestamps**: `upsert` MUST keep `createdAt` from the stored entry
  when one exists (else use the given `createdAt`), and MUST set `updatedAt` to
  the current time. The stored entry used for `createdAt` (and for
  `secretFields` when `secrets` is absent) MUST be read in the same write
  transaction that writes the row. This in-transaction read decides `createdAt`
  and the kept `secretFields`; the earlier read that decides which secrets are
  removed is a different one (`upsert-stale-read`).
- **upsert-secrets-nil-keeps**: `upsert` called with `secrets` absent MUST leave
  every stored secret untouched and MUST set the entry's `secretFields` to the
  stored entry's list when one exists; for an entry with no stored row it MUST
  keep the `secretFields` the given entry carried.
- **upsert-secrets-replace**: `upsert` called with a secrets dictionary MUST
  write each non-empty value to the secret store under the entry's id and field
  name, and MUST remove from the secret store every field the stored entry had
  that the dictionary does not carry with a non-empty value.
  The stored entry used here is the one `get(_:)` returns before any secret is
  written (`upsert-stale-read`).
- **upsert-stale-read**: The stale-field set MUST come from a read made outside
  the write transaction, before the secret writes, while `createdAt` and the
  `secretFields` kept for an absent `secrets` MUST come from the read inside the
  transaction. A concurrent writer that adds a field between the two reads MAY
  therefore leave that field's Keychain value in place but absent from
  `secretFields` (a `secretFields`/Keychain mismatch); the registry does not
  guard against it.
- **upsert-secrets-empty-dropped**: `upsert` MUST treat an empty secret value
  the same as a field left out: nothing is written and any stored value for that
  field is removed.
- **upsert-secret-fields**: After `upsert` with a secrets dictionary the stored
  entry's `secretFields` MUST be the sorted names of the non-empty values given,
  plus any stale field whose removal failed (`secret-removal-failure`).
- **upsert-secret-write-failure**: `upsert` MUST propagate the secret store's
  error when a secret write fails, and MUST NOT write the entry row or post the
  signal in that case. Secrets of the same call written before the failure MUST
  NOT be rolled back, so for an entry with no stored row they remain in the
  Keychain with no row naming them (`secret-write-orphan`).
- **secret-write-orphan**: A failed `set` after earlier `set`s of the same
  `upsert` call MUST leave those earlier values stored. For a new entry no row
  names them, and for an existing entry a field it did not already name is
  likewise untracked; a later successful `upsert` of the same id with the same
  field names overwrites them.
- **upsert-signals**: `upsert` MUST post the change signal once, after the row
  is written.
- **remove-deletes**: `remove(_:)` MUST remove from the secret store each field
  named in the stored entry's `secretFields`, and then delete the row.
- **remove-absent-ok**: `remove(_:)` MUST NOT throw for an id that has no row,
  and MUST still post the change signal.
- **remove-signals**: `remove(_:)` MUST post the change signal once, after the
  row is deleted and the secrets are removed.

### Resolution

- **resolve-role**: `resolve(role:)` MUST return the first entry in `list()`
  order that is enabled and whose `roles` contains the role by exact string
  equality, and MUST return no entry when none matches. Because it reads `list()`, it MUST
  throw when any stored row fails to decode (`list-decode-failure`), even when
  the corrupt row is not the one that would match.
- **resolve-selector-role**: `resolve(_:)` on `.role(role)` MUST return the entry
  of `resolve(role:)`, with the model set to that entry's `effectiveModel`, and
  MUST return no result when no entry matches.
- **resolve-selector-config**: `resolve(_:)` on `.config(id, override)` MUST
  return the entry with that id with the model set to `override` when `override`
  is non-empty, else to the entry's `effectiveModel`, and MUST return no result
  when no entry has the id.
- **resolve-disabled**: `resolve(_:)` on `.config` MUST return no result when
  the named entry has `enabled` false, because disabling an entry takes it out of
  service everywhere.
- **resolve-secrets**: A resolved model MUST carry, for each name in the entry's
  `secretFields`, the value the secret store holds, and MUST omit a name whose
  stored value is absent.
- **request-values**: `ResolvedModel.request(descriptor:)` MUST return the
  model `descriptor.effectiveModel(stored:templateId:)` yields for the resolved
  model, and a value bag that starts from the template's `defaultValues`, is
  overlaid by the entry's `fields` (the entry's value winning), has every secret
  field the template declares set from the resolved secrets (the empty string when
  missing), and has the key `model` set last to the chosen model.
- **effective-model-order**: `AIPluginDescriptor.effectiveModel(stored:templateId:)`
  MUST return the stored model when non-empty, else the template's resolved
  default model when non-empty, else the descriptor's resolved default model.
- **request-secret-scope**: `AIPluginDescriptor.requestValues` MUST include only
  the secret fields of the named template (its own field list, or the
  descriptor's shared list when the template id no longer resolves), so a keyless
  template does not gain a blank `apiKey`.

### Plugins and models

- **plugins-listing**: `plugins()` MUST return one `PluginSummary` per
  descriptor the runtime discovers in the search paths, ordered by `displayName`
  with a case-insensitive, locale-aware comparison, and MUST NOT load plugin code.
- **plugin-summary-template**: Each `PluginSummary.Template` MUST carry the
  template's `id`, `displayName`, `models`, `secretRequired`, `defaultValues`, its
  own field list, and a `defaultModel` computed with no stored model.
- **list-models-source**: `listModels(_:)` MUST return the model ids of the
  provider's live list when the provider has a model source and loading it
  answers, and MUST otherwise return the template's static `models`.
- **list-models-inputs**: `listModels(_:)` MUST pass the entry's plugin
  identifier, template, the entry's `baseURL` field (absent when not set) and the
  `apiKey` secret (absent when not set) to the provider's model manager.
- **list-models-errors**: `listModels(_:)` MUST throw `ModelRegistryError.notFound`
  for an unknown id, `pluginNotInstalled` when no discovered descriptor has the
  entry's plugin identifier, and `unknownTemplate` when the plugin has no template
  with the entry's template id.
- **test-round-trip**: `test(_:)` MUST send one request whose model is the one
  `ResolvedModel.request(descriptor:)` yields for the entry's `effectiveModel`
  (so `effective-model-order` decides: the entry's model, else the template's
  default, else the descriptor's), with the single user message
  `Reply with the single word OK.`, no system prompt and a maximum of 64 tokens,
  and MUST accumulate the text deltas until the stream ends.
- **test-success**: `test(_:)` MUST return `isOK` true, the reply trimmed of
  surrounding whitespace and newlines as `message`, and the elapsed milliseconds
  as `latencyMs` when the trimmed reply is non-empty.
- **test-empty-reply**: `test(_:)` MUST return `isOK` false with the message
  `Empty reply from the model` when the trimmed reply is empty.
- **test-never-throws**: `test(_:)` MUST NOT throw: any error (unknown id,
  plugin not installed, request build failure, stream failure) MUST come back as
  `isOK` false with the error's localized description as `message` and the
  elapsed milliseconds as `latencyMs`.
- **test-ignores-other-events**: `test(_:)` MUST ignore thinking deltas, tool
  uses and usage events, and MUST stop reading the stream at its end event.

### Change notification

- **change-signal-name**: The registry's default change signal MUST be the Darwin
  notification named `com.agenticdevelopmentstudio.models.changed`
  (`ModelRegistry.changeNotificationName`).
- **changes-stream**: `changes` MUST return a new `AsyncStream<Void>` that yields
  once after a write by any process holding the registry, this process included.
- **changes-per-stream-observer**: Each `changes` stream MUST observe its own
  signal instance, created by the injected signal factory, and MUST release it
  when the stream ends, because a signal holds one handler and a second `observe`
  replaces the first.
- **changes-coalesce**: A `changes` stream MUST buffer at most one pending
  yield, so writes that land before the consumer reads collapse into one yield.

### Secret store

- **secret-store-contract**: A `ModelSecretStore` MUST offer `value(for:field:)`
  (nil when absent), `set(_:for:field:)` (throws on failure) and
  `remove(for:field:)` (throws on failure; an absent value is not a failure), one value per entry id and field name.
- **secret-store-keys**: `SharedGroupModelSecrets` MUST address a value by the
  account `AIProviderConfigKeys.fieldKey(config:field:)`, the same service and
  account names the apps' own provider settings use, so an app that imported a
  configuration and the daemon read the same item.
- **secret-store-write-failure**: `SharedGroupModelSecrets.set` MUST throw
  `ModelSecretStoreError.writeFailed(field:)`, described as
  `Could not store the secret '<field>' in the Keychain`, when the Keychain
  refuses the write.
- **secret-store-keychain-choice**: `SharedGroupModelSecrets` created with no
  keychain MUST use the shared Keychain group when the process is entitled to it,
  and otherwise MUST use the same service in the process's own Keychain.
- **secret-store-announce**: `SharedGroupModelSecrets` MUST post its configured
  change notification (default `AIProviderSharedSecretsProvider.changeNotificationName`)
  after every successful `set` and every `remove`, and MUST post nothing when the name is nil.
- **secret-removal-failure**: `SharedGroupModelSecrets.remove` MUST throw `ModelSecretStoreError.removeFailed(field:)`, described as `Could not remove the secret '<field>' from the Keychain`, when the Keychain refuses the delete. In `upsert` a stale field whose removal fails MUST stay in `secretFields`, the row MUST still be written and signalled, and `upsert` MUST then throw that error. In `remove(_:)` a failed secret removal MUST throw before the row is deleted, leaving the entry stored so the removal can be retried, and MUST post no signal.

### Concurrency and ordering

- **registry-sendable**: `ModelRegistry` MUST be a `Sendable` final class that
  holds only immutable references, so one instance MAY be called from any thread
  or task.
- **database-serialization**: Reads and writes MUST go through `BoundedDatabase`,
  which serialises writes and reads from a pool in WAL mode; the registry adds no
  lock of its own.
- **concurrent-upsert**: Two `upsert` calls of one id, from one process or several, MUST be last-writer-wins for the row: each reads the stored row and writes its own in one database write transaction, so neither loses the stored `createdAt`. Secret values are written field by field before that transaction and are not part of it, so concurrent calls MAY interleave: the secret store MAY hold a mix of both calls' values, and the surviving row's `secretFields` MAY come from the other writer than some of the Keychain values (`upsert-stale-read`). The registry guarantees nothing about secrets beyond each field holding some call's value.
- **list-models-main-actor**: `listModels(_:)` MUST resolve the provider's model
  source on the main actor and MUST load it off the main actor.
- **app-import**: `ModelRegistryImport.run(_:into:origin:)` MUST upsert each source as an entry with the source configuration's id, its non-secret fields, its model and the given `origin`, passing its secrets to `upsert(_:secrets:)`. It MUST skip a source when the registry already holds an entry with its id, or an entry of the same plugin identifier with equal non-secret fields, and MUST report each source as imported, skipped or failed by id without any secret value. A failed upsert MUST NOT stop the remaining sources.
- **app-import-once**: `ModelRegistryImport.runIfNeeded` MUST read the app's `aiplugin.configurations` with their field values (secret fields through the app's own Keychain provider) on the main actor, MUST do nothing when `models_registry_imported_v1` is set in the given defaults, and MUST set that flag only when no upsert failed, so a failure is retried at the next launch. A configuration whose template no longer resolves MUST be reported unresolved and not imported.

