---
id: 12d36a57-8d7d-454e-a2ee-44effbd9e93b
title: "Model Registry"
type: ingredient
version: 1.1.0
status: review
language: en
created: 2026-11-25
modified: 2026-11-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The suite's shared list of model configurations: one SQLite file, secrets in the shared Keychain, role and id resolution, and a cross-process change signal."
platforms:
  - swift
  - macos
tags:
  - ai
  - model-registry
  - provider
  - persistence
depends-on: []
related:
  - c8438764-89c9-4286-9b58-10c9cd175a97
references: []
approved-by: ""
approved-date: ""
---

# Model Registry

## Overview

The model registry is the suite's shared list of model configurations. Every
app and daemon on the Mac opens the same SQLite file; each entry (`ModelEntry`)
names a provider configuration (a plugin and one of its templates), its
non-secret field values, a default model, and the free-form roles it can fill
(`fast`, `smart`, `local`, `cheap`). Secret values (API keys and the like)
never enter the file: they live in a `ModelSecretStore` (the shared Keychain
group in production), and the entry stores only the names of its secret fields.
After every write the registry posts a cross-process change signal (a Darwin
notification in production) so every process holding the registry re-reads.

A consumer names the model it wants with a `ModelSelector`: a role, resolved
to the first enabled entry holding it, or a specific entry id with an optional
model override. Resolution yields a `ResolvedModel` (entry, model, secrets)
that `ResolvedModel.request(descriptor:)` turns into the model id and value bag
a plugin builds a request from. The registry also lists installed plugins
(`PluginSummary`, read from descriptors, no plugin code loaded), lists the
models an entry's provider offers, and runs a one-line round trip to an
entry's model (`ModelTestResult`).

It is a **logic** component with no visual surface. It is related to the
[adhsdk.ingredient.ai.models.model-catalog](cookbook:c8438764-89c9-4286-9b58-10c9cd175a97) only in that
both describe models for provider templates; the registry stores user
configurations and the catalog stores shared facts about model ids.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a persistent store, resolver and secret-store seam, not
a visual component.

## States

Not applicable — this is a persistent store, resolver and secret-store seam, not
a visual component. Its one runtime lifecycle (opened and migrated, then
serving reads and writes) is covered under Behavioral Requirements
(`store-migration`, `upsert-signals`, `changes-stream`), not as a visual-state table.

## Accessibility

Not applicable — this is a persistent store, resolver and secret-store seam, not
a visual component.

## Conformance Test Vectors

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
| MR-051 | app-import (`ModelRegistryImportTests.importsOne`) | Import one source with field `baseURL`, secret `apiKey`, model `m1`, origin `com.example.app` | The entry keeps the source's id, fields, model and origin; `secretFields` is `["apiKey"]` and the secret store holds the value |
| MR-052 | app-import (`ModelRegistryImportTests.skipsDuplicates`, `reportsFailure`) | Import a source twice; import a same-plugin source with equal fields and one with different fields; import a blank-named source before a valid one | Skipped by id; the twin is skipped and the other imported; the blank one fails, the valid one is imported and no failure message holds a secret |

## Edge Cases

- **Empty and missing input**: an entry with a blank name, empty plugin
  identifier or empty template id MUST be rejected before anything is written
  (`upsert-validation`). A selector with an empty override MUST fall back to the
  entry's default model, not ask for an empty model name (`resolve-selector-config`).
  A minimal entry payload with only `configuration` MUST decode with defaults
  (`entry-minimal-decode`).
- **Unknown and absent ids**: `get` of an absent id MUST return none; `remove` of
  an absent id MUST succeed; `resolve` of an absent id MUST return none;
  `listModels` of an absent id MUST throw `notFound`; `test` of an absent id MUST
  return a failed result rather than throw.
- **Boundary values**: an empty secret value is the same as no secret
  (`upsert-secrets-empty-dropped`). A name made only of a newline is not trimmed
  to empty, because only spaces and tabs are trimmed. The `updated_at` column holds
  fractional seconds but the JSON dates are ISO-8601 at whole-second precision, so
  `updatedAt` read back from the JSON MAY be rounded down to the second.
- **Error states**: a secret write failure MUST abort `upsert` before the row is
  written, and earlier secrets of the same call stay stored: for a new entry
  that leaves Keychain values no row names (`secret-write-orphan`), a known gap
  rather than a rollback; a database
  failure MUST propagate from the call that hit it. An undecodable row MUST make
  `list()` throw (`list-decode-failure`), and so every `resolve(role:)` and
  role-based `resolve(_:)` throws too, whichever entry would have matched;
  `get`, `.config` resolution and `remove` read one row and are unaffected. A failed `test` MUST be a result, not a
  thrown error. A live model list that fails or answers nothing MUST fall back to
  the template's static list, with no error surfaced to the caller.
- **Concurrent access**: the registry is `Sendable` and may be called from any
  thread, and several processes share the file; the database serialises writes.
  An upsert of one id from two processes at once is last-writer-wins for the
  row and keeps the stored `createdAt` (`concurrent-upsert`). Two `changes` streams each hold their own
  signal so neither replaces the other's handler.
- **Concurrent writers and secrets**: two `upsert` calls of one id may interleave
  their field-by-field secret writes, leaving a mix of both calls' values, and a
  stale-field removal decided from the pre-transaction read may miss a field a
  concurrent writer just added (`concurrent-upsert`, `upsert-stale-read`).
- **Offline or disconnected**: the store and the Keychain are local and need no
  network. `listModels` and `test` contact the provider over its own transport; an
  unreachable provider makes `listModels` fall back to the static list and `test`
  return a failed result with the error's description. The registry sets no
  timeout, retry or cancellation of its own on either call.
- **Missing environment**: a process without the shared-Keychain entitlement MUST
  read and write the same service in its own Keychain, so entries it creates are
  not visible to other processes' secret reads (`secret-store-keychain-choice`). A
  plugin removed after an entry was created MUST make `listModels` throw
  `pluginNotInstalled` and `test` return a failed result.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `storeURL` | URL | `~/Library/Application Support/com.agenticdevelopmentstudio.models/models.sqlite` | The SQLite file; its parent directory is created. |
| `database` | `BoundedDatabase` | opened at `storeURL` | The designated initializer takes an open database; a test passes `:memory:`. |
| `secrets` | `ModelSecretStore` | `SharedGroupModelSecrets()` | Where secret values live. |
| `runtime` | `DaemonAIChat.PluginRuntime` | `.live` | Loads plugins, runs requests and discovers descriptors; a test substitutes a scripted one. |
| `searchPaths` | list of URL | `DaemonAIChat.pluginSearchPaths()` | Where plugins are looked for; the agent host loads from the same places. |
| `makeSignal` | `@Sendable` factory of `CrossProcessSignal` | A `DarwinNotificationSignal` named `com.agenticdevelopmentstudio.models.changed` | One instance posts; each `changes` stream observes its own. |
| `keychain` | `AIProviderSecretKeychain` (secret store) | The shared group when entitled, else the process Keychain | Where `SharedGroupModelSecrets` stores values. |
| `changeNotificationName` | optional string (secret store) | `AIProviderSharedSecretsProvider.changeNotificationName` | The Darwin notification the secret store posts after a write; nil posts nothing. |

The registry reads no environment variable and no settings key.

## Deep Linking

Not applicable: the registry is a store with no URL surface; its source defines no scheme or route.

## Localization

The registry produces user-facing error text in English only, with no localization mechanism:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal) | `A model entry needs a name` | `ModelRegistryError.invalidEntry`, name blank |
| (none; literal) | `A model entry needs a plugin identifier` | `invalidEntry`, plugin identifier empty |
| (none; literal) | `A model entry needs a template id` | `invalidEntry`, template id empty |
| (none; literal) | `No model entry with id <uuid>` | `ModelRegistryError.notFound` |
| (none; literal) | `AI plugin not installed: <plugin>` | `ModelRegistryError.pluginNotInstalled` |
| (none; literal) | `AI plugin <plugin> has no template '<template>'` | `ModelRegistryError.unknownTemplate` |
| (none; literal) | `Could not store the secret '<field>' in the Keychain` | `ModelSecretStoreError.writeFailed` |
| (none; literal) | `Could not remove the secret '<field>' from the Keychain` | `ModelSecretStoreError.removeFailed` |
| (none; literal) | `Empty reply from the model` | `ModelTestResult.message` on an empty reply |
| (none; literal) | `Reply with the single word OK.` | The test prompt sent to the model (not shown to the user) |

## Accessibility Options

Not applicable: the registry has no visual or motion output, so Reduce Motion, Increase Contrast and Differentiate Without Color have nothing to act on.

## Feature Flags

Not applicable: the source reads no feature flag; every operation is always available.

## Analytics

Not applicable: the source emits no analytics event.

## Privacy

- **Data collected**: Model configurations the user or an importing app supplies (name, plugin and template ids, non-secret fields, default model, roles, origin bundle id) and secret values such as API keys.
- **Storage**: Entries in the SQLite file under the user's Application Support folder, which holds no secret value (`entry-no-secret-values`). Secret values in the Keychain (the shared group when entitled, else the process Keychain), under the account `AIProviderConfigKeys.fieldKey(config:field:)`.
- **Transmission**: The registry itself sends nothing. `listModels` sends the entry's `baseURL` and `apiKey` to the provider's model-listing endpoint, and `test` sends the test prompt and the entry's configuration to the provider through its plugin.
- **Retention**: Until `remove` deletes the row and its named secrets. The registry has no expiry, and a secret the Keychain refuses to delete stays named in the entry's `secretFields` (or keeps the entry stored), so a failed removal never orphans an untracked item (`secret-removal-failure`). A failed secret write partway through an `upsert` can leave earlier values of that call in the Keychain with no row naming them (`secret-write-orphan`).

## Logging

Not applicable: the source calls no logger; failures are thrown or returned as a `ModelTestResult`.

## Platform Notes

- **SwiftUI**: The source is Swift and runs in the app and daemon processes. A settings screen for the registry observes `changes` with a `for await` loop inside a `task` modifier and calls `list()` again on each yield; `ModelRegistry` is `Sendable`, so it can sit in an `@Observable` view model or an environment value. Source files: `Agents/Models/ModelRegistry.swift`, `ModelEntry.swift`, `ModelSelector.swift`, `ModelRegistryTypes.swift`, `ModelSecretStore.swift`, and `AIPluginKit/AIPluginDescriptor+Request.swift`, with tests in `ModelRegistryTests.swift` (Swift Testing, a fake secret store, a fake signal and a scripted plugin runtime).
- **Compose**: Hold the registry in a `ViewModel` and expose `list()` as a `StateFlow`; collect a `callbackFlow` or `Flow` of change events to refresh. A native port stores entries in Room (a table with an id key and a JSON text column) or SQLite, keeps secrets encrypted with a key held in the Android Keystore (for example through Tink's `AndroidKeysetManager`; `EncryptedSharedPreferences` is deprecated), and replaces the Darwin notification with a `ContentObserver` or broadcast; the cross-process shared file and shared Keychain group have no direct Android equivalent.
- **React/Web**: Model the registry as a module over IndexedDB (an object store keyed by id holding the entry JSON) or a server table; secrets belong on a server, never in browser storage. Replace the change signal with a `BroadcastChannel` for tabs, expose changes as an `AsyncIterable` or an event emitter, and use `crypto.randomUUID()` for ids and `localeCompare` with `sensitivity: "accent"` for the case-insensitive name order.
- **AppKit / UIKit**: The same Swift code serves macOS AppKit apps and daemons. The Darwin notification (`CFNotificationCenterGetDarwinNotifyCenter`) reaches every process of the user session and carries no data, so each process re-reads; the shared-group Keychain needs the `keychain-access-groups` entitlement, and a process without it falls back to its own Keychain. Source is macOS-targeted; the same files use Foundation, GRDB and the SDK's own modules (Core, Database, AIPluginKit).
- **WinUI 3**: Use a .NET class library. Store entries with `Microsoft.Data.Sqlite` (a table with a text id key, a JSON column and a real timestamp column, created by a versioned migration run at startup) and serialise them with `System.Text.Json` (`JsonSerializerOptions` with a `DateTime` converter for ISO-8601, `JsonNamingPolicy` unchanged, and `[JsonPropertyName("ok")]` on `IsOk`). Keep secrets in the Windows Credential Locker (`Windows.Security.Credentials.PasswordVault`, resource name for the service and user name for the entry-and-field account) behind an `IModelSecretStore` interface. Run reads and writes on `Task` and `async` methods; `list` order uses `StringComparer.CurrentCultureIgnoreCase` then ordinal id compare. Model `changes` as an `IAsyncEnumerable<Unit>` built from a bounded `System.Threading.Channels.Channel` with `BoundedChannelFullMode.DropOldest` and capacity 1; cross-process signalling uses a named `EventWaitHandle` or a `FileSystemWatcher` on the database file instead of a Darwin notification. Resolution returns an immutable `record ResolvedModel`; `test` uses `Stopwatch` for `LatencyMs` and returns a result rather than throwing.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Agents/Models/` | unverified |
| apple | `packages/apple/AgenticDeveloperHubSDK/Agents/Providers/ModelRegistryImport.swift` | unverified |

## Design Decisions

**Decision**: Secrets live outside the entry: the stored JSON holds only the secret field names, and values go to a `ModelSecretStore`.
**Rationale**: A SQLite file in Application Support is readable by anything running as the user and is copied by backups, while the Keychain is access-controlled; keeping values out of the file means a leaked or shared database exposes no credentials. The names let a resolver know which secrets to read without loading the plugin.
**Approved**: pending

**Decision**: Disabling an entry takes it out of service for role and id resolution alike.
**Rationale**: A user who disables an entry expects no feature to keep calling that provider, including a feature that pinned the entry by id; if only role lookup honoured the flag, a stored selector would silently bypass the user's choice (`disabledEntryDoesNotResolve`).
**Approved**: pending

**Decision**: An absent `secrets` argument keeps stored secrets, while a dictionary replaces them, with empty values removing a secret.
**Rationale**: This lets an edit that renames an entry leave the Keychain untouched, while a settings form that submits the full secret set can delete a secret by clearing its field (`secretUpdates`).
**Approved**: pending

**Decision**: Each `changes` stream observes its own signal instance, created by an injected factory.
**Rationale**: A signal holds one handler and a second `observe` replaces the first, so sharing one would let a new stream silence an older one. The stream buffers only the newest yield because consumers re-read the whole list, so queued yields would only repeat the same re-read.
**Approved**: pending

**Decision**: `test` returns a `ModelTestResult` for every failure instead of throwing.
**Rationale**: The result is shown to a person configuring an entry, so a failure is data (`isOK` false with a message), and latency is reported on failure too.
**Approved**: pending

**Decision**: Secret work goes before the row change, and the row's read and write share one transaction: `upsert` writes secrets first, `remove` deletes secrets first. `remove` throws before deleting the row and posts no signal when a secret removal fails; `upsert` with a failed stale removal still writes and signals, then throws.
**Rationale**: The Keychain cannot join a SQLite transaction, so the order decides what a failure leaves behind. Secrets first means a failed write leaves no row change and a failed delete leaves the entry naming the secret, so a failed removal never orphans a Keychain item. It does not cover a failed write partway through a multi-secret `upsert`: values already written stay, and for a new entry no row names them (`secret-write-orphan`); the order narrows the orphan window, it does not close it. Reading the stored row inside the write transaction makes concurrent upserts last-writer-wins without losing `createdAt` (`concurrent-upsert`, `secret-removal-failure`). The stale-field set is read earlier, outside the transaction, because the removals must run before it opens (`upsert-stale-read`).
**Approved**: pending

**Decision**: The request value bag lists declared secrets even when blank, and scopes them to the named template.
**Rationale**: A blank-but-present key lets `buildRequest` tell "needs a key and it is blank" from "keyless", so it can report the missing key; scoping to the named template avoids a keyless template (Ollama) being rejected for a blank key it never needed.
**Approved**: pending

**Decision**: `list-decode-failure` lets one corrupt row fail the whole listing.
**Rationale**: Fail fast over silent data loss: skipping a corrupt row would make a configured model vanish from every picker and role resolution with no signal. Throwing surfaces the corruption to the caller. The cost is that one bad row also breaks `resolve(role:)` for every role (`resolve-role`), and the registry offers no repair path; a recovery plan (a repair or quarantine call that names the failing row id) is pending.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` passes because the registry owns storage, resolution
and the change signal only, while secret custody sits behind `ModelSecretStore`,
plugin discovery and request execution behind `DaemonAIChat.PluginRuntime`, and
the mapping from a stored configuration to a request bag in
`AIPluginDescriptor+Request.swift`. `unit-test-coverage` is partial:
`ModelRegistryTests.swift` covers ordering, secret handling, timestamps, removal,
validation, role and selector resolution, request values, plugin listing, `test`,
the change signal and the wire forms, but no test covers `listModels`, a failing
secret write, a corrupt row, the change coalescing, the keychain choice, or a
selector with an unknown type. `secure-storage` passes because secret values go
only to the Keychain and never into the SQLite file or the entry JSON.
`explicit-error-handling` is partial: a failed secret delete throws
`removeFailed` (`secret-removal-failure`), but a failed live model list
silently falls back to the static list. `data-integrity` is partial because
the row's read-modify-write is one transaction (`concurrent-upsert`) but the
Keychain writes are not part of it. `no-hardcoded-strings` fails because every error
description and the empty-reply message are English literals with no
localization mechanism.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.0 | 2026-11-25 | Mike Fullerton | Add app-import and app-import-once: ModelRegistryImport copies an app's provider configurations into the registry once (MR-051, 052) |
| 1.0.0 | 2026-11-25 | Mike Fullerton | Initial creation |
