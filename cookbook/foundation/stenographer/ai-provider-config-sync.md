---
id: b05ceb21-7c1c-4d62-83ba-01a3132df00a
title: "AI Provider Config Sync"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The app-to-daemon wire contract carrying the whole set of resolved AI provider configurations, with an optional list of ids to delete for partial syncs."
platforms:
  - swift
  - macos
tags:
  - foundation
  - stenographer
  - ai-provider
  - dto
  - sync
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# AI Provider Config Sync

## Overview

`AIProviderConfigSync` is the app-to-daemon wire contract for AI provider configuration. It replaces the old flattened untyped dictionary push and carries the whole set of configurations, so the daemon mirrors the full registry keyed by configuration identity rather than a single plugin-keyed slot. `ResolvedProviderConfig` is one configuration on the wire: its identity plus the resolved value bag, split into non-secret `values` and `secrets`.

The summaries switch and the summaries configuration are not part of this contract: `POST /preferences/summaries` is their only writer. The two fields that once carried them, `enabled` and `selectedConfigId`, stay for wire compatibility and the daemon ignores them.

Both types are `Codable`, `Sendable` and `Equatable` structs with `var` properties. They live in Core so an HTTP client can send them without importing the plugin layer; `AIPluginKit` re-exports them as type aliases so existing `import AIPluginKit` call sites compile unchanged.

## Behavioral Requirements

- **sync-fields**: `AIProviderConfigSync` MUST carry `enabled` (`Bool`), `selectedConfigId` (`UUID?`), `configs` (`[ResolvedProviderConfig]`) and `removedConfigIds` (`[UUID]?`).
- **enabled-ignored**: `enabled` is kept for wire compatibility only: the daemon ignores it, and whether summaries run is set through `POST /preferences/summaries`.
- **selected-ignored**: `selectedConfigId` is kept for wire compatibility only: the daemon ignores it, and the summaries configuration is set through `POST /preferences/summaries`.
- **whole-registry**: `configs` MUST hold every configured provider, fully resolved (values and secrets).
- **nil-removed-full-sync**: When `removedConfigIds` is nil or absent, as an older host sends, `configs` MUST be the complete registry and the daemon deletes every stored configuration it lists no longer.
- **non-nil-removed-partial-sync**: When `removedConfigIds` is non-nil, the sync is partial: the daemon upserts `configs`, deletes exactly the listed ids and leaves every other stored configuration alone.
- **empty-removed-is-partial**: An empty non-nil `removedConfigIds` MUST count as a partial sync that deletes nothing, not as a full sync.
- **sync-initializer**: The initializer MUST take `enabled`, `selectedConfigId` and `configs` without defaults, and `removedConfigIds` defaulting to nil.
- **sync-decode-tolerance**: A payload with no `removedConfigIds` key MUST decode with that field nil, and a payload with no `selectedConfigId` key MUST decode with that field nil.
- **sync-decode-required**: A payload missing `enabled` or `configs` MUST fail to decode, because the synthesized conformance requires non-optional keys.
- **config-fields**: `ResolvedProviderConfig` MUST carry `id` (`UUID`), `name`, `pluginIdentifier`, `templateId`, `model` (all `String`), `values` and `secrets` (both `[String: String]`).
- **config-initializer**: The `ResolvedProviderConfig` initializer MUST take every field with no defaults.
- **values-secrets-split**: Non-secret entries MUST travel in `values` and credentials in `secrets`.
- **empty-secret-clears**: An empty secret value MUST mean "clear this credential".
- **config-keyed-by-id**: The daemon persists each configuration under `AIProviderConfigKeys` keyed by `id`, so `id` MUST be the configuration's stable identity across pushes.
- **round-trip**: Encoding then decoding a sync MUST produce an equal value, including `selectedConfigId`, each configuration and its `values` and `secrets`.
- **aliases**: `AIPluginKit` MUST re-export `AIProviderConfigSync` and `ResolvedProviderConfig` as type aliases of the Core types.

## Appearance

Not applicable — this is a wire data contract, not a visual component.

## States

Not applicable — this is a wire data contract, not a visual component.

## Accessibility

Not applicable — this is a wire data contract, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ai-provider-config-sync-001 | round-trip, sync-fields, config-fields | A sync with `enabled` true, a `selectedConfigId`, and one configuration with a `baseURL` value and an `apiKey` secret; encode then decode. | The decoded value equals the original (test: testRoundTrip). |
| ai-provider-config-sync-002 | sync-decode-tolerance | Decode `{"enabled":false,"configs":[]}`. | `selectedConfigId` is nil, `enabled` is false, `configs` is empty (test: testDecodesMissingSelectionAsNil). |
| ai-provider-config-sync-003 | nil-removed-full-sync, sync-decode-tolerance | Decode `{"enabled": true, "configs": []}`. | `removedConfigIds` is nil (test: testSyncDecodesWithoutRemovedConfigIds). |
| ai-provider-config-sync-004 | sync-initializer | Build a sync without passing `removedConfigIds`. | `removedConfigIds` is nil (derived from the source default; no test). |
| ai-provider-config-sync-005 | empty-removed-is-partial | Build a sync with `removedConfigIds` of an empty array and encode it. | The encoded key is present as an empty array, which the daemon reads as a partial sync; the ledger tests record syncs of exactly this shape (test: AIConfigPushLedgerTests, testARecordedPushThenADroppedConfigurationIsRemoved). |
| ai-provider-config-sync-006 | non-nil-removed-partial-sync | A sync with `removedConfigIds` of one id and one config. | The daemon upserts the config, deletes that one id and leaves other stored configurations (source: the daemon's `applyAIProviderSync`; no test given here). |
| ai-provider-config-sync-007 | nil-removed-full-sync | A sync with nil `removedConfigIds` listing one config. | The daemon deletes every stored configuration not in `configs` (source: the daemon's `applyAIProviderSync`; no test given here). |
| ai-provider-config-sync-008 | sync-decode-required | Decode `{"configs":[]}`. | Decoding throws `keyNotFound` for `enabled` (derived from the synthesized conformance; no test). |
| ai-provider-config-sync-009 | empty-secret-clears | A configuration with `secrets` of `apiKey` set to the empty string. | The wire value is the empty string, which the daemon reads as clearing the credential (source: the doc comment; no test). |
| ai-provider-config-sync-010 | aliases | `AIPluginKit` consumers use `AIProviderConfigSync`. | The name resolves to the Core type; the round-trip test in `AIPluginKitTests` compiles against the alias (test: testRoundTrip). |
| ai-provider-config-sync-011 | config-initializer | Build `ResolvedProviderConfig` with no `values` or `secrets` arguments. | Does not compile; both are required (derived from the source; compile-time). |

## Edge Cases

- **Null / empty input**: A sync with empty `configs` and nil `removedConfigIds` is a full sync that deletes every stored configuration. With an empty non-nil `removedConfigIds` it deletes nothing. An empty `values` or `secrets` map is valid.
- **Boundary values**: Not applicable: the contract holds no numeric limits; its size is the number of configurations.
- **Concurrent access**: Not applicable to the types, which are `Sendable` values. The daemon serialises the apply: its `applyAIProviderSync` takes a lock so HTTP and XPC callers cannot interleave; that behavior is outside this file.
- **Error states**: A payload missing `enabled` or `configs` fails to decode, and a malformed UUID in `id`, `selectedConfigId` or `removedConfigIds` fails to decode, each throwing a `DecodingError`. The types validate no field contents: an empty `name` or unknown `templateId` is accepted.
- **Offline / disconnected state**: Not applicable: the types do no networking. Each push sends one body; delivery, retries and acknowledgement belong to the sender, and the ledger records only a push that landed.
- **Older host**: A host that predates `removedConfigIds` omits the key, and the daemon then treats the sync as the complete registry. A partial-sync host must therefore always send the key, even when empty, or it risks deleting another host's configurations.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| removedConfigIds | `[UUID]?` | nil | Choose partial sync (non-nil) or full sync (nil). |

The types read no environment variable or settings key.

## Deep Linking

Not applicable: the types define no URL scheme or route; `POST /preferences/summaries`, named in the comments, is a daemon route outside this file.

## Localization

Not applicable: the types hold no user-facing string; `name` is user-entered data carried as is.

## Accessibility Options

Not applicable: the types present no UI.

## Feature Flags

Not applicable: the source contains no feature-flag reference.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data handled**: `secrets` carries credentials such as API keys in plain text inside the struct and its encoded body, alongside the non-secret `values`.
- **Storage**: None by the types. The daemon persists non-secret values in its settings table and secrets in the keychain (the keychain service is injected into the daemon's `SecretStoring`; the identifiers define one per daemon, `ADKDIdentifiers.keychainService` for the Kitchen daemon and `StenographerIdentifiers.daemonKeychainService` for Stenographer's); those writes are outside this file.
- **Transmission**: The body travels from app to daemon over loopback HTTP or XPC. The types add no encryption; no timeout, idempotency key or redaction exists in them.
- **Retention**: Not applicable to the types; the daemon keeps a configuration until a sync deletes it.

## Logging

Not applicable: the types call no logging API.

## Platform Notes

- **SwiftUI**: Source is `Core/Stenographer/AIProviderConfigSync.swift`, importing only `Foundation`: two public structs conforming to `Codable`, `Sendable` and `Equatable`, with `var` properties and explicit initializers. `AIPluginKit/AIProviderConfigSyncAliases.swift` re-exports both as type aliases. Because Swift's synthesized `Decodable` uses `decodeIfPresent` for optionals, the two optional fields tolerate missing keys.
- **Compose**: Use `@Serializable` Kotlin `data class` types with `val removedConfigIds: List<String>? = null` and `val selectedConfigId: String? = null`. Set `explicitNulls = false` and default optionals to null so a missing key decodes, and keep an empty list distinct from null when encoding.
- **React/Web**: TypeScript interfaces with `selectedConfigId?: string | null` and `removedConfigIds?: string[]`. Preserve the difference between an omitted or undefined key and an empty array when building the body; for example, always include `removedConfigIds` for partial syncs.
- **AppKit / UIKit**: Identical to the SwiftUI note: the types are UI-framework-agnostic and the macOS app builds them in `StenographerAIConfigPush`.
- **WinUI 3**: Use C# `record` types with `System.Text.Json`. Declare `RemovedConfigIds` as `IReadOnlyList<Guid>?` and `SelectedConfigId` as `Guid?` so missing keys deserialize to null, and mark `Enabled` and `Configs` `[JsonRequired]` to match the source. Keep `JsonIgnoreCondition.Never` on `RemovedConfigIds` so an empty list is written as an empty array. Send with `HttpClient.PostAsJsonAsync`. Store secrets locally in `Windows.Security.Credentials.PasswordVault` rather than in a settings file.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/AIProviderConfigSync.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The sync carries the whole set of configurations rather than a single plugin-keyed slot.
**Rationale**: The source comment states the daemon mirrors the full registry keyed by configuration identity.
**Approved**: pending

**Decision**: `removedConfigIds` distinguishes a partial sync (non-nil) from a full one (nil).
**Rationale**: Two hosts share one daemon registry, so a host must be able to delete exactly what it dropped; nil keeps older hosts working as full-set mirrors.
**Approved**: pending

**Decision**: `enabled` and `selectedConfigId` stay on the wire though the daemon ignores them.
**Rationale**: The source comments say they are kept for wire compatibility only; summaries state has a single writer, `POST /preferences/summaries`.
**Approved**: pending

**Decision**: Secrets travel in the same body as values, in a separate `secrets` map where an empty value clears the credential.
**Rationale**: The source describes the split so the daemon can store each part in its proper place, and an empty value is the only clear signal the contract has.
**Approved**: pending

**Decision**: The contract lives in Core with aliases in the plugin layer.
**Rationale**: The aliases file states it moved down so an HTTP client can send it without importing the plugin layer, and the aliases keep existing call sites compiling.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | Security |

`separation-of-concerns` passes because the types only describe the wire shape; applying it, persisting it and recording what landed are done elsewhere. `unit-test-coverage` is partial because tests cover the round trip, the missing selection and the missing removal list, but not the missing-key failures or the daemon's full versus partial semantics from this file. `secure-transport` is partial because the body carries secrets in clear text over loopback HTTP or XPC, with no encryption or redaction in the types; the transport's protections belong to the sender and daemon.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
