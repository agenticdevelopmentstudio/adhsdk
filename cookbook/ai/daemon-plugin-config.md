---
id: 01d9e414-c3aa-49f9-9c30-cef95de3aec0
title: "Daemon Plugin Config"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Key convention a daemon uses to store AI plugin selection, plugin field values and secret-field ledger, with percent-encoded components to prevent collisions."
platforms:
  - swift
  - macos
tags:
  - plugin-config
  - storage-keys
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Daemon Plugin Config

## Overview

`DaemonPluginConfig` is a caseless `enum` that defines the storage-key convention a daemon uses for AI plugin configuration. The host app pushes the selected plugin's field values to the daemon; the daemon persists non-secret fields in its settings table and secret fields in its own Keychain namespace under keys built here, then resolves them back into an `AIPluginConfig` at completion time. The doc comment is explicit about scope: the wire protocol (the `fields` and `secrets` maps keyed by descriptor field key) is the cross-process contract, while these key strings are "an internal daemon detail, so they need only agree with themselves". The component contains no storage code; it only names keys. In the current source its callers are the daemon's one-time legacy cleanup in `PreferencesService`; configurations the daemon stores now are keyed through `AIProviderConfigKeys`.

## Behavioral Requirements

- **namespace-only**: The component MUST be a stateless namespace (a caseless enum) with only static members and no state.
- **selected-plugin-key**: `selectedPluginKey` MUST equal the literal `ai_plugin_id`. It names the settings-table key that holds the identifier of the plugin to complete with.
- **selected-plugin-empty-means-claude-cli**: An empty or absent value at `selectedPluginKey` MUST mean "use the zero-config claude_cli path", per the key's doc comment. The component only documents this meaning; the reader of the key applies it. In the current source the key is read and then reset to empty only by the daemon's one-time legacy cleanup in `PreferencesService`.
- **field-key-format**: `fieldKey(plugin:field:)` MUST return `aiplugin.<encoded plugin>.field.<encoded field>`.
- **secret-fields-key-format**: `secretFieldsKey(plugin:)` MUST return `aiplugin.<encoded plugin>.secretfields`.
- **component-encoding**: Each dynamic component (plugin identifier, field key) MUST be percent-encoded with only ASCII-and-Unicode alphanumerics left unescaped, so every other character, including `.` and `%`, is escaped.
- **dot-escaped**: A `.` in a component MUST appear as `%2E`, so it cannot be read as a structural delimiter.
- **plain-ids-stay-readable**: A component made only of alphanumeric characters MUST pass through unchanged.
- **distinct-pairs-distinct-keys**: Two distinct (plugin, field) pairs MUST map to distinct field keys. This is the collision-freedom guarantee in the doc comment, and it holds because the encoding escapes both `.` and `%`.
- **ledger-never-collides-with-field**: The secret-fields ledger key for a plugin MUST differ from the field key of any field of that plugin, including a field named `secretfields`, because the field key always carries the extra `field` segment.
- **deterministic**: The same inputs MUST return the same key on every call, with no salting or ordering dependence, so a value written in one request is found in the next.
- **ledger-purpose**: The ledger key MUST be the place the daemon records the newline-joined descriptor field keys whose secrets it holds for a plugin. The doc comment says the daemon records it on write so it can clear exactly those Keychain entries on a plugin switch, because it cannot enumerate its own secret namespace. In the current source the only caller that reads it is the daemon's legacy cleanup in `PreferencesService` (`clearStoredSecrets(forPlugin:)`, run from `cleanUpLegacyIfNeeded`); the registry that stores configurations today keys its values and ledgers through `AIProviderConfigKeys` instead.
- **no-io**: The component MUST NOT read or write the settings table, the Keychain or any file; storage belongs to the caller.
- **encoding-fallback**: When percent-encoding returns nil, the component MUST fall back to the raw, unencoded text for that component.
- **thread-safety**: Every member MUST be safe to call concurrently, since all are pure functions of their arguments.

## Appearance

Not applicable — this is a storage-key convention for a background daemon, not a visual component.

## States

Not applicable — this is a storage-key convention for a background daemon, not a visual component. It holds no state and has no runtime state machine.

## Accessibility

Not applicable — this is a storage-key convention for a background daemon, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| daemon-plugin-config-001 | field-key-format, plain-ids-stay-readable | `fieldKey(plugin: "acme", field: "apiKey")` | `aiplugin.acme.field.apiKey` (`DaemonPluginConfigTests.testFieldKeyShapeIsStable`) |
| daemon-plugin-config-002 | dot-escaped, component-encoding | `fieldKey(plugin: "com.example.plugin", field: "apiKey")` | `aiplugin.com%2Eexample%2Eplugin.field.apiKey` (`DaemonPluginConfigTests.testReverseDNSIdentifierEncodesItsDots`) |
| daemon-plugin-config-003 | distinct-pairs-distinct-keys | `fieldKey(plugin: "plugin.a", field: "apiKey")` versus `fieldKey(plugin: "plugin.b", field: "apiKey")` | The two keys differ (`DaemonPluginConfigTests.testDistinctPluginsWithSameFieldGetDistinctKeys`) |
| daemon-plugin-config-004 | distinct-pairs-distinct-keys | `fieldKey(plugin: "x.field.y", field: "z")` versus `fieldKey(plugin: "x", field: "y.field.z")` | The two keys differ (`DaemonPluginConfigTests.testDelimiterCollisionIsPrevented`) |
| daemon-plugin-config-005 | secret-fields-key-format, ledger-never-collides-with-field | `secretFieldsKey(plugin: "acme")` versus `fieldKey(plugin: "acme", field: "secretfields")` | Ledger is `aiplugin.acme.secretfields`; it differs from the field key (`DaemonPluginConfigTests.testSecretFieldsLedgerKeyNeverCollidesWithAFieldKey`) |
| daemon-plugin-config-006 | deterministic | Call `fieldKey(plugin: "p", field: "f")` and `secretFieldsKey(plugin: "p")` twice each | Equal results per pair (`DaemonPluginConfigTests.testKeysAreDeterministic`) |
| daemon-plugin-config-007 | selected-plugin-key | Read `selectedPluginKey` | `ai_plugin_id` |
| daemon-plugin-config-008 | component-encoding | `fieldKey(plugin: "a%b", field: "c d")` | `aiplugin.a%25b.field.c%20d` |
| daemon-plugin-config-009 | component-encoding | `fieldKey(plugin: "", field: "")` | `aiplugin..field.` (an empty component stays empty) |

## Edge Cases

- **Empty plugin or field text**: An empty component encodes to the empty string, so `fieldKey(plugin: "", field: "k")` is `aiplugin..field.k`. The component performs no emptiness check; callers own it. MUST.
- **Delimiter-like text**: A plugin or field containing `.`, `field` or `secretfields` MUST NOT alias another pair's key, because dots are escaped. MUST.
- **Percent sign in a component**: A literal `%` is escaped as `%25`, so an already-encoded input is encoded again and never aliases its decoded form. MUST.
- **Non-ASCII letters**: The allowed set is the platform's alphanumerics, which includes Unicode letters and digits, so those pass through unescaped. A port MUST match the same character set or the keys will differ. MUST.
- **Encoding failure fallback**: If the platform encoder returns nil the raw text is used, which would reintroduce delimiter ambiguity for that component. The source gives no case where this happens for a Swift `String`. MUST (stated as the actual behavior).
- **Ledger value format**: The ledger value is newline-joined field keys; a field key that contains a newline would be split into two entries when read back with a newline split, and empty entries are dropped on read in `PreferencesService`. MUST (stated as observed behavior of the caller).
- **Concurrent access**: Not applicable — every member is a pure function with no shared state.
- **Error states and offline state**: Not applicable — the component performs no I/O and has no dependency that can fail or disconnect.
- **Boundary length**: No length limit is applied; very long components produce very long keys, and limits of the settings table or Keychain are outside this component. MUST.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `selectedPluginKey` | `String` constant | `ai_plugin_id` | Settings-table key for the identifier of the plugin to complete with; empty or absent means the claude_cli path. |
| `plugin` | `String` | none (required) | Plugin identifier, usually reverse-DNS, for `fieldKey` and `secretFieldsKey`. |
| `field` | `String` | none (required) | Descriptor field key for `fieldKey`. |

The component defines no environment variable. Its keys are stored by the daemon in its settings table and Keychain namespace.

## Deep Linking

Not applicable: the component defines no URL scheme, route or navigation destination.

## Localization

Not applicable: the component builds machine keys, not user-facing text.

## Accessibility Options

Not applicable: the component presents no UI, so it responds to no Reduce Motion, Increase Contrast or Differentiate Without Color setting.

## Feature Flags

Not applicable: the component contains no feature-flag reference; its `ai_plugin_id` key selects a plugin, not a feature.

## Analytics

Not applicable: the component contains no analytics or event-tracking call.

## Privacy

- **Data collected**: The component handles plugin identifiers and field keys as key text. It never sees field values or secrets, only the names under which the daemon stores them.
- **Storage**: None by the component. Per its doc comment the daemon stores non-secret fields in its settings table and secret fields in its own Keychain namespace under these keys.
- **Transmission**: None by the component; keys are an internal daemon detail and the wire protocol carries descriptor field keys, not these strings.
- **Retention**: None by the component. The secret-fields ledger exists so the daemon can delete a plugin's Keychain secrets on a plugin switch; `PreferencesService.clearStoredSecrets(forPlugin:)` does that by reading the ledger.

## Logging

Not applicable: the component contains no logging call.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/AIPluginKit/DaemonPluginConfig.swift`, in the Foundation-only `AIPluginKit` module. It has no UI dependency, so SwiftUI and AppKit hosts are unaffected; only the daemon uses the keys, through `PreferencesService` (its legacy cleanup) (`Database/Daemon/Preferences/PreferencesService.swift`).
- **Compose**: Keep the same key shapes in a Kotlin `object`. Percent-encode with `java.net.URLEncoder` only after checking that it escapes `.` and `*` the way Swift's `.alphanumerics` does; it does not by default, so write an explicit encoder that leaves only `Character.isLetterOrDigit` characters raw. Store non-secret values in `DataStore` or Room and secrets in the Android Keystore through `EncryptedSharedPreferences`.
- **React/Web**: Write the encoder by hand: `encodeURIComponent` leaves `.`, `-`, `_` and `~` unescaped, so it does not guarantee the collision freedom this component relies on. Escape every character that is not a letter or digit as `%XX` of its UTF-8 bytes. A browser has no Keychain; keep secrets server-side or in a platform vault.
- **AppKit / UIKit**: The reference is `AIPluginKit/DaemonPluginConfig.swift`, an `enum` using `String.addingPercentEncoding(withAllowedCharacters: .alphanumerics)`. The `.alphanumerics` set is Unicode-aware, so it keeps non-ASCII letters raw. The test class is `DaemonPluginConfigTests` in `Tests/AIPluginKitTests`. The settings table and Keychain namespace are owned by the daemon's `PreferencesService` and its secret store.
- **WinUI 3**: Use a `static class DaemonPluginConfig` with `const string SelectedPluginKey = "ai_plugin_id"`. Write the encoder as a `StringBuilder` loop that keeps characters where `char.IsLetterOrDigit` is true and appends `%XX` per UTF-8 byte of each other character (`Encoding.UTF8.GetBytes`); `Uri.EscapeDataString` leaves `.` and `-` raw and so does not match. Persist non-secret fields with `Windows.Storage.ApplicationData.Current.LocalSettings` (or the daemon's own database) and secrets in `Windows.Security.Credentials.PasswordVault` or DPAPI via `ProtectedData`; a Windows service port would use the same keys in its own store.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/AIPluginKit/DaemonPluginConfig.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Each dynamic key component is percent-encoded with only alphanumerics left raw.
**Rationale**: Plugin identifiers are reverse-DNS and contain dots, which are also the key's structural delimiter. Escaping the dot and the percent sign makes the join injective, so two different (plugin, field) pairs can never share a key and one plugin's credential cannot overwrite or leak into another's. The test file states this purpose.
**Approved**: pending

**Decision**: The key strings are an internal daemon detail, not a cross-process contract.
**Rationale**: The doc comment says the wire protocol is the `fields` and `secrets` maps keyed by descriptor field key; the keys here "need only agree with themselves". A port may therefore choose different key strings provided its own reads and writes agree, but it MUST keep the collision-freedom property.
**Approved**: pending

**Decision**: A separate ledger key records which secret fields are stored for a plugin.
**Rationale**: The daemon cannot enumerate its own secret namespace, so on a plugin switch it reads the ledger to know which Keychain entries to clear. The ledger key lacks the `field` segment so it can never equal a field key, even for a field named `secretfields`.
**Approved**: pending

**Decision**: An empty `selectedPluginKey` value selects the zero-config claude_cli path.
**Rationale**: The doc comment defines empty or absent as the default path, so no plugin has to be configured for completion to work.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.privacy-and-data.secure-data-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9d865cfa-ff98-5b90-b5da-58a611d3535b) | partial | privacy-and-data |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | reliability |

The enum only names keys and never touches storage, which keeps naming apart from persistence. Six tests cover key shape, dot encoding, distinct plugins, delimiter collisions, the ledger key and determinism; the `selectedPluginKey` literal and the percent-sign case have no test. Secure storage is partial because this component only names the Keychain namespace; where and how secrets are stored is the daemon's code, outside these sources. Data integrity passes because the encoding makes distinct pairs map to distinct keys.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
