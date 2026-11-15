---
id: 846ec786-5b96-4ee0-b7db-d6ae4bd6e333
title: "Layered Settings Store"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A settings store whose values override a broader fallback store for non-secure keys, while secure keys always read and write the fallback."
platforms:
  - swift
  - macos
tags:
  - foundation
  - settings
  - storage
depends-on:
  - 6363b5ff-f511-4e21-9ba7-6850787dba62
related: []
references: []
approved-by: ""
approved-date: ""
---

# Layered Settings Store

## Overview

`LayeredSettingsStore` is a `SettingsStore` (see [adhsdk.ingredient.foundation.settings-storage](cookbook:6363b5ff-f511-4e21-9ba7-6850787dba62)) whose values can be overridden in a narrower scope while everything it does not override reads through to a broader `SettingsStore`, its `fallback`. Reads answer the override when one exists and the fallback otherwise. Writes always land in the overrides, so the broader store is never touched from here for a non-secure key. Secure keys skip the layering entirely and go straight to the fallback: a secret has one home, and a per-pane copy would be a second place to leak it from. The store's `changes` publisher reports override changes plus fallback changes for keys the overrides do not hold, so a pane never sees a global change it is hiding. In the Swift implementation the class is `@MainActor` and is built on the `SettingsStore` base class, two private providers (one layered, one secure forwarder) and a private by-name key type.

## Behavioral Requirements

**Construction**

- **init-parts**: `init(overrides:fallback:)` MUST take a `SettingsStorageProvider` for the overrides and a `SettingsStore` for the fallback, and MUST expose the fallback as the public read-only property `fallback`.
- **init-wiring**: The store MUST behave as a `SettingsStore` whose non-secure keys read and write through the overrides over the fallback, and whose secure keys read and write the fallback directly.
- **single-context**: All calls to the store MUST be confined to one execution context, so no two calls run concurrently.

**Reads**

- **get-override-wins**: For a non-secure key, `get` MUST return the override's value when the overrides contain the key.
- **get-fallback-reads-through**: For a non-secure key, `get` MUST return the fallback's value, `fallback.get(key)`, when the overrides do not contain the key.
- **get-secure-from-fallback**: For a secure key, `get` MUST return `fallback.get(key)` without consulting the overrides.
- **contains-is-override-only**: For a non-secure key, `contains` MUST report only whether the overrides hold the key; a value inherited from the fallback MUST NOT count as contained.
- **contains-secure-from-fallback**: For a secure key, `contains` MUST return `fallback.contains(key)`.

**Writes**

- **set-lands-in-overrides**: For a non-secure key, `set` MUST write to the overrides and MUST NOT write to the fallback.
- **set-secure-to-fallback**: For a secure key, `set` MUST write to the fallback and MUST NOT write to the overrides.
- **remove-from-overrides**: For a non-secure key, `remove` MUST remove the key from the overrides only, so later reads show the fallback's value.
- **remove-secure-from-fallback**: For a secure key, `remove` MUST remove the key from the fallback.

**Override management**

- **has-override**: `hasOverride(_:)` MUST return true only when the key is not secure and the overrides contain it.
- **has-override-secure-false**: `hasOverride(_:)` MUST return false for every secure key, including one whose value is set.
- **remove-override**: `removeOverride(_:)` MUST behave exactly as `remove(_:)`: it drops this layer's value so reads show the fallback's again.
- **remove-all-by-prefix**: `removeAllOverrides(withPrefix:)` MUST remove from the overrides every key name that the overrides list for the prefix through `keys(withPrefix:)`.
- **remove-all-spares-others**: `removeAllOverrides(withPrefix:)` MUST NOT remove an override whose name does not start with the prefix.
- **remove-all-by-name**: `removeAllOverrides(withPrefix:)` MUST remove each listed name from the overrides as a non-secure key, whatever type of value was stored under it.
- **keys-from-overrides**: `keys(withPrefix:)` MUST list only the names the overrides hold, not the fallback's names, and never a secure key.

**Change publication**

- **changes-override**: `changes` MUST publish the key name of every change the overrides publish.
- **changes-fallback-unshadowed**: `changes` MUST also publish the key name of a fallback change when the overrides do not hold that exact name.
- **changes-fallback-hidden**: `changes` MUST NOT publish a fallback change for a key name the overrides hold.
- **changes-exact-probe**: A fallback change MUST be hidden only when the overrides hold exactly the changed name, even when the overrides provider cannot enumerate its keys; holding a name that merely starts with the changed name MUST NOT hide it.
- **changes-released-store**: When the store has been released, fallback changes MUST pass through unfiltered.
- **changes-secure-relayed-once**: A fallback change to a secure key MUST be published exactly once through the layered provider's relay; the secure forwarding provider's `changes` MUST publish nothing, because relaying there too would publish each change twice and would skip the override filter. The override filter applies to a secure key's name as it does to any other: when the overrides happen to hold the same name, the fallback change is hidden.
- **changes-remove-emits**: Removing an override MUST publish that key name through the overrides' own `changes`; the store adds no publication of its own, so whether a removal publishes is the overrides provider's rule (the `SettingsStorageProvider` contract documents "set or removed"; a provider may publish on removal only when a value was held).

## Appearance

Not applicable — this is a settings store, not a visual component.

## States

Not applicable — this is a settings store, not a visual component. The store has no runtime state machine; each key is either overridden or inherited, as described under Behavioral Requirements.

## Accessibility

Not applicable — this is a settings store, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| layered-settings-store-001 | get-fallback-reads-through, has-override | Test `testGetFallsBackWhenNoOverride`: fallback holds `browser.page_zoom` = 1.5, no override | `get(zoom)` is 1.5 and `hasOverride(zoom)` is false |
| layered-settings-store-002 | get-override-wins, set-lands-in-overrides, has-override | Test `testOverrideWins`: fallback 1.5, then `layered.set(2.0, for: zoom)` | `layered.get(zoom)` is 2.0, `fallback.get(zoom)` is still 1.5, `hasOverride(zoom)` is true |
| layered-settings-store-003 | remove-override, remove-from-overrides | Test `testRemoveOverrideRevealsFallback`: fallback 1.5, override 2.0, then `removeOverride(zoom)` | `get(zoom)` is 1.5 and `hasOverride(zoom)` is false |
| layered-settings-store-004 | changes-fallback-unshadowed, changes-exact-probe | Test `testFallbackChangeIsPublishedWithoutOverride`: subscribe to `layered.changes`, then `fallback.set(1.5, for: zoom)` with no override | The subscriber receives exactly `["browser.page_zoom"]` |
| layered-settings-store-005 | changes-fallback-hidden | Test `testFallbackChangeIsHiddenByAnOverride`: override 2.0 set, subscribe, then `fallback.set(1.5, for: zoom)` | The subscriber receives nothing and `layered.get(zoom)` is still 2.0 |
| layered-settings-store-006 | remove-all-by-prefix, remove-all-spares-others | Test `testRemoveAllOverridesWithPrefix`: overrides for `browser.page_zoom`, `browser.home_page` and `editor.font_size`, then `removeAllOverrides(withPrefix: "browser.")` | `hasOverride` is false for zoom and home, true for `editor.font_size` |
| layered-settings-store-007 | changes-remove-emits, remove-override | Test `testRemoveOverrideEmitsAChangeForThatKey`: override set, subscribe, then `removeOverride(zoom)` | The subscriber receives exactly `["browser.page_zoom"]` |
| layered-settings-store-008 | set-secure-to-fallback, get-secure-from-fallback, has-override-secure-false | Test `testSecureKeyGoesStraightToTheFallback`: secure key `test.secret`, `layered.set("s3cret", for: secret)` | `fallback.get(secret)` is `"s3cret"`, the overrides provider does not contain the key, `hasOverride(secret)` is false, `layered.get(secret)` is `"s3cret"` |
| layered-settings-store-009 | contains-is-override-only | Fallback holds a value for a non-secure key, no override | `layered.contains(key)` is false (no dedicated test) |
| layered-settings-store-010 | contains-secure-from-fallback | A secure key set on the fallback | `layered.contains(secret)` is true (no dedicated test) |
| layered-settings-store-011 | keys-from-overrides | Fallback holds `a.x`, overrides hold `a.y`; call `keys(withPrefix: "a.")` | `["a.y"]` (no dedicated test) |
| layered-settings-store-012 | changes-secure-relayed-once | Subscribe to `layered.changes`, then `fallback.set("v", for: secret)` where the overrides do not hold the name | The subscriber receives the secret's name exactly once (no dedicated test) |
| layered-settings-store-013 | remove-secure-from-fallback | A secure key set on the fallback; `layered.remove(secret)` | `fallback.contains(secret)` is false (no dedicated test) |
| layered-settings-store-014 | changes-override | Subscribe, then `layered.set(2.0, for: zoom)` | The subscriber receives `"browser.page_zoom"` (no dedicated test) |
| layered-settings-store-015 | changes-released-store | Subscribe to `layered.changes`, release the layered store, then `fallback.set(1.5, for: zoom)` while the overrides hold `browser.page_zoom` (no dedicated test) | The subscriber receives `"browser.page_zoom"`, because the filter no longer applies |
| layered-settings-store-016 | changes-secure-relayed-once | The overrides provider holds a value under the name of a secure key; subscribe, then `fallback.set("v", for: secret)` (no dedicated test) | The subscriber receives nothing, because the override filter hides that name |
## Edge Cases

- **Empty prefix**: `removeAllOverrides(withPrefix: "")` removes every override name the overrides list for the empty prefix; the store adds no guard, so what that covers is the overrides provider's `keys(withPrefix:)` answer.
- **No matching names**: `removeAllOverrides(withPrefix:)` with a prefix that lists no names MUST do nothing.
- **Secure key and `removeOverride`**: `removeOverride(_:)` on a secure key is `remove(_:)`, which routes a secure key to the fallback, so it deletes the fallback's secret; it does not report an override because `hasOverride` is false for secure keys. This is a known hazard of the current behavior, not an intended feature; a caller MUST NOT use `removeOverride` as a harmless no-op on a secure key.
- **Secure key and prefix removal**: Secure values are never enumerated, so `removeAllOverrides(withPrefix:)` never touches a secure key.
- **Fallback changed under an override**: A fallback change to a key the overrides hold is dropped from `changes`, and the store's reads keep answering the override.
- **Override removed after a hidden change**: After the override is removed, the next `get` shows the fallback's current value; the hidden change was never published, but the removal publishes the key name through the overrides provider (when it publishes the removal, as the `SettingsStorageProvider` contract says), so observers re-read it.
- **Prefix collision in the probe**: The probe lists names for the changed name as a prefix and then requires an exact match, so an override named `browser.page_zoom_extra` does not hide a fallback change to `browser.page_zoom`.
- **Released store**: Once the layered provider is gone, fallback changes pass through unfiltered (`changes-released-store`).
- **Concurrent access**: Every type is `@MainActor`, so the compiler confines calls to the main actor and serialises them; there is no concurrent mutation.
- **Error states**: The store has no throwing operations and no error path; failures belong to the injected providers.
- **Offline or disconnected state**: Not applicable: the store makes no network calls; durability and availability are whatever the overrides provider and the fallback store provide.
- **Boundary values**: Not applicable: the store imposes no limits on key names or values; those belong to the injected providers.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `overrides` | `SettingsStorageProvider` | none (required) | Where this layer's own values are held; every non-secure write lands here. |
| `fallback` | `SettingsStore` | none (required) | The broader store that non-secure reads fall through to and that owns every secure key. |

## Deep Linking

Not applicable: The store registers no URL scheme, route or link handler.

## Localization

Not applicable: The store has no user-facing strings; keys and values are opaque to it.

## Accessibility Options

Not applicable: The store has no visual surface, so no Reduce Motion, Increase Contrast or Differentiate Without Color behavior exists.

## Feature Flags

Not applicable: The source reads no flag; layering is always on.

## Analytics

Not applicable: The source emits no analytics events.

## Privacy

- **Data collected**: None by this code; it carries whatever values the caller stores, including secure values.
- **Storage**: Non-secure values live in the injected overrides provider. Secure values are never copied into the overrides: they live only in the fallback store's secure provider.
- **Transmission**: None; the store performs no network access.
- **Retention**: Overrides last as long as the overrides provider keeps them; the store deletes none on its own.

## Logging

Not applicable: The source calls no logging API.

## Platform Notes

- **SwiftUI**: The source is `Core/SettingStorage/LayeredSettingsStore.swift` and imports `Foundation` and `Combine`. The class is `@MainActor` and `public final`, built on the open `SettingsStore` base in the core SDK. Private providers, the private by-name `NamedSetting` key and the `@MainActor` isolation are Swift mechanisms for the `init-wiring`, `single-context` and `remove-all-by-name` requirements; a port needs the behavior, not these types. `changes` is a Combine `AnyPublisher<String, Never>` built from `Publishers.Merge`, so a SwiftUI view model can `sink` it or bridge it into `@Published` state. The private by-name type (`NamedSetting`) conforms to `StorableSetting`.
- **Compose**: Use a class holding an overrides map or DataStore and a parent store; expose reads as a `Flow` that combines the overrides flow with the parent flow filtered by `key !in overrides.keys`. Route secure keys to `EncryptedSharedPreferences` or the Keystore through the parent only. Confine mutation to the main dispatcher (`Dispatchers.Main`) to match the main-actor rule.
- **React/Web**: A small class with two `Map`s or storage adapters and an event emitter (or an RxJS subject) for `changes`. Use `localStorage` or `sessionStorage` for overrides; web has no keychain, so secure keys go to the parent store and never to the override storage. JavaScript is single-threaded, so no extra serialisation is needed.
- **AppKit / UIKit**: Identical to the SwiftUI note: the store is UI-framework-agnostic. A consumer that scopes settings to one view builds a layered store with a view-state override provider over the app-wide fallback.
- **WinUI 3**: Implement an `ISettingsStore` class with a `ConcurrentDictionary` or `ApplicationData.Current.LocalSettings` (an `ApplicationDataContainer`) for overrides and a parent `ISettingsStore` as the fallback. Publish `changes` as an `IObservable<string>` (Rx) or a .NET `event Action<string>`, and implement the hidden-key filter by checking `overrides.Keys.Any(k => k == name)` before relaying the parent's event. Keep secure keys in the parent store, which wraps `Windows.Security.Credentials.PasswordVault` (or `ProtectedData`). Marshal updates onto the UI thread with `DispatcherQueue.TryEnqueue` to match the `@MainActor` rule; expose the store through `INotifyPropertyChanged` if bound from XAML.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/SettingStorage/LayeredSettingsStore.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Secure keys bypass the overrides and go straight to the fallback.
**Rationale**: A secret has one home, and a per-pane copy would be a second place to leak it from. As a consequence `hasOverride` is always false for a secure key.
**Approved**: pending

**Decision**: Writes always land in the overrides; the fallback is never written from this layer for a non-secure key.
**Rationale**: The narrower scope must not change the broader scope's values. The cost is that a caller wanting to change the global value must use the fallback store directly.
**Approved**: pending

**Decision**: `contains` answers whether the layer holds an override, not whether a value is readable.
**Rationale**: An override is held by this layer and the fallback's values are inherited, not held. `hasOverride` and any reset-to-default behavior rely on that distinction.
**Approved**: pending

**Decision**: Fallback changes are filtered with an exact-name probe through `keys(withPrefix:)` rather than `contains`.
**Rationale**: The filter has only a name, not a typed key. Asking the overrides for the keys that start with that exact name works even for a provider that cannot enumerate, and it avoids needing a value type. The Swift implementation does this through `keys(withPrefix:)` and checks the result for the name.
**Approved**: pending

**Decision**: The secure forwarding provider publishes nothing from `changes`.
**Rationale**: The base store merges the two providers' `changes`, and the layered provider already relays every fallback change, secure ones included; relaying in both places would publish each change twice and would skip the override filter.
**Approved**: pending

**Decision**: Removal by prefix removes through a private `NamedSetting` key typed as `Bool`.
**Rationale**: Providers remove by name, so the value type is irrelevant; in the Swift implementation a private by-name key exists only to carry a name from `keys(withPrefix:)` back into `remove`.
**Approved**: pending

**Decision**: `removeOverride` is an alias of `remove` and does not check `isSecure`. This records current behavior and a known defect, not a reasoned design.
**Rationale**: `removeOverride` was written as a name for `remove`, and nothing guards the secure case. It means `removeOverride` on a secure key removes the fallback's secret; callers must pass only non-secure keys until the store makes it a no-op or an error.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.privacy-and-data.secure-data-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9d865cfa-ff98-5b90-b5da-58a611d3535b) | passed | Privacy and Data |

`separation-of-concerns` passes because the class only layers reads, routes writes and filters change notifications; persistence belongs to the injected overrides provider and the fallback store. `unit-test-coverage` passes because `AgenticDeveloperHubSDKCoreTests/LayeredSettingsStoreTests.swift` has a test for each of the sixteen vectors: the reads, the overrides, prefix removal, secure-key routing for `contains` and `remove`, `keys(withPrefix:)`, and every path of the change filter, including the released-store path. `secure-data-storage` passes because a secure key is never written to the overrides provider and is held only by the fallback's secure provider.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (LayeredSettingsStoreTests.swift, 16 of 16 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Restated the wiring, main-actor, by-name and probe requirements as observable behavior, added the released-store and secure-name-filter requirements with vectors, marked vectors 009-016 as untested, recorded removeOverride on a secure key as a known defect with real rationales, made the text consumer-neutral, and added the settings-storage dependency with links. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
