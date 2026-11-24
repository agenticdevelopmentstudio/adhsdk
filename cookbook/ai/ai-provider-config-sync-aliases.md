---
id: 1aa874c5-bdeb-4068-8e52-15791ac04647
title: "AI Provider Config Sync Aliases"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Two public type aliases that keep the AI provider wire contract resolvable through the plugin layer after the types moved down to the Core framework."
platforms:
  - swift
  - macos
tags:
  - ai-plugin
  - type-alias
  - wire-contract
depends-on:
  - 1d7812e7-28cb-4874-897f-43aab62fe009
related:
  - 0f65ea61-3b0f-4a9b-842e-912555b7af62
  - ef2a5ca9-04a4-46ab-8fef-3fdc6db2041d
references: []
approved-by: ""
approved-date: ""
---

# AI Provider Config Sync Aliases

## Overview

This component is one source file holding two public type aliases, `AIProviderConfigSync` and `ResolvedProviderConfig`, in the plugin layer framework. Each alias names the type of the same name in the Core framework. Its own comment gives the reason: "The AI provider wire contract moved down to Core (`Core/Stenographer/`) so an HTTP client can send it without importing the plugin layer. These aliases keep every existing `import AIPluginKit` call site compiling unchanged." The aliases add no field, no behavior and no conformance of their own: a value built through the alias is the Core value. The wire contract itself (the sync envelope and the resolved provider configuration record) is specified by [Provider Configuration Synchronization](cookbook:1d7812e7-28cb-4874-897f-43aab62fe009); this recipe covers only the aliasing seam.

## Behavioral Requirements

- **sync-alias**: The plugin layer MUST expose `AIProviderConfigSync` as a public type alias for the Core framework's `AIProviderConfigSync`.
- **resolved-config-alias**: The plugin layer MUST expose `ResolvedProviderConfig` as a public type alias for the Core framework's `ResolvedProviderConfig`.
- **alias-identity**: A value created through either alias MUST be interchangeable, with no conversion, with a value of the Core type, because an alias is another name for one type and not a new type.
- **import-compatibility**: A call site that imports only the plugin layer MUST be able to name both types, construct them with their Core initializers and encode or decode them, so call sites written before the move compile unchanged.
- **core-ownership**: The wire shape MUST be defined once, in the Core framework, so an HTTP client can send it without importing the plugin layer; the plugin layer MUST NOT redeclare either type.
- **inherited-contract**: Every field, default and conformance (`Codable`, `Sendable`, `Equatable`) of the aliased types is the Core type's: `AIProviderConfigSync` carries `enabled`, `selectedConfigId`, `configs` and `removedConfigIds` (optional, default nil), and `ResolvedProviderConfig` carries `id`, `name`, `pluginIdentifier`, `templateId`, `model`, `values` and `secrets`.
- **no-behavior**: The file MUST contain no function, property or logic; it declares only the two aliases and imports the Core framework.
- **no-error-domain**: The component MUST NOT define or throw an error; decode errors come from the Core types' synthesized decoding.

## Appearance

Not applicable — this is a pair of type aliases, not a visual component.

## States

Not applicable — this is a pair of type aliases with no lifecycle and no runtime state machine.

## Accessibility

Not applicable — this is a pair of type aliases, not a visual component.

## Conformance Test Vectors

The plugin layer's own test target imports only the plugin layer and exercises the aliases (`AIProviderConfigSyncTests`).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ai-provider-config-sync-aliases-001 | import-compatibility, sync-alias, resolved-config-alias | Build a sync envelope with `enabled: true`, a selected id and one resolved configuration ("Groq", "com.x.openai-compatible", "custom", model "llama-3.3-70b", values with a base URL, secrets with an API key), encode it and decode it again (`testRoundTrip`) | The decoded value equals the original |
| ai-provider-config-sync-aliases-002 | inherited-contract | Decode `{"enabled":false,"configs":[]}` through the alias (`testDecodesMissingSelectionAsNil`) | `selectedConfigId` is absent, `enabled` is false, `configs` is empty |
| ai-provider-config-sync-aliases-003 | inherited-contract | Construct a sync envelope without passing `removedConfigIds` | `removedConfigIds` is nil |
| ai-provider-config-sync-aliases-004 | alias-identity | Pass a value built through the alias to the Core HTTP client's AI preferences call, which takes the Core type | The call compiles and accepts the value with no conversion |
| ai-provider-config-sync-aliases-005 | inherited-contract | Decode `{"enabled":true,"configs":[],"removedConfigIds":["11111111-2222-3333-4444-555555555555"]}` | `removedConfigIds` holds that one identifier |
| ai-provider-config-sync-aliases-006 | core-ownership | Search the plugin layer for a declaration of a type named `AIProviderConfigSync` or `ResolvedProviderConfig` | Only the two aliases exist there; the struct declarations are in the Core framework |

## Edge Cases

- **Null and empty input**: Not applicable — the aliases hold no data; empty configuration lists and absent selections are the Core types' behavior (see the synchronization recipe).
- **Boundary values**: Not applicable — the aliases have no constrained input.
- **A call site importing both frameworks**: it MUST see one type under two names; there is no ambiguity because an alias is not a distinct declaration.
- **A call site importing only Core**: it MUST still reach the types directly; the aliases are an addition for plugin-layer importers, not a replacement.
- **Removing the aliases later**: every `import AIPluginKit` call site naming either type would stop compiling; the source's comment says that is exactly what the aliases prevent.
- **Concurrent access**: Not applicable — the aliases are compile-time names; the aliased types are `Sendable`.
- **Error states and offline state**: Not applicable — the file performs no network, database or file-system call.

## Configuration

Not applicable as options: the file takes no parameter. Its one dependency is the import of the Core framework (`AgenticDeveloperHubSDKCore`), which supplies both aliased types.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Core framework import | module dependency | required | The plugin layer MUST link the Core framework for the aliases to resolve. |

## Deep Linking

Not applicable: the source defines no URL, route or navigable destination.

## Localization

Not applicable: the source contains no user-facing string.

## Accessibility Options

Not applicable: the file renders nothing and reads no accessibility display setting.

## Feature Flags

Not applicable: the source declares no feature-flag key and contains no conditional logic.

## Analytics

Not applicable: the source contains no analytics or event-emission call.

## Privacy

- **Data collected**: None by the aliases themselves; the aliased resolved configuration carries provider credentials in its `secrets` map, as described in the synchronization recipe.
- **Storage**: None in this file.
- **Transmission**: None in this file; the Core HTTP client sends the aliased envelope.
- **Retention**: None in this file.

## Logging

Not applicable: the file contains no logging call.

## Platform Notes

- **SwiftUI**: not applicable to this file; it imports only the Core framework. A SwiftUI settings screen would use the aliased types as it would the Core types.
- **Compose**: Kotlin has `typealias` with the same effect; declare `typealias AIProviderConfigSync = core.AIProviderConfigSync` in the plugin module only if call sites need the old name, and keep the `@Serializable` data classes in the lower module.
- **React/Web**: use a re-export from the higher package's index, for example `export type { AIProviderConfigSync, ResolvedProviderConfig } from "<core-package>"`, so imports from the old path keep resolving while one declaration owns the shape.
- **AppKit / UIKit**: this is the source. The file is `packages/apple/AgenticDeveloperHubSDK/AIPluginKit/AIProviderConfigSyncAliases.swift`, two `public typealias` lines in the `AIPluginKit` framework that name the structs in `Core/Stenographer/AIProviderConfigSync.swift`. The Core structs are used by the HTTP client (`StenographerHTTPClient`) and by the daemon preferences service, which decodes the same type.
- **WinUI 3**: C# has no cross-assembly type alias. Reach the same effect with a `global using AIProviderConfigSync = Company.Core.AIProviderConfigSync;` directive in the consuming project, which is file or project scoped, or by type forwarding with `[assembly: TypeForwardedTo(typeof(...))]` when a type moves between assemblies and compiled consumers must keep working. Keep the `record` types and their `System.Text.Json` attributes in the lower assembly only.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/AIPluginKit/AIProviderConfigSyncAliases.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The wire types live in the Core framework and the plugin layer re-exposes them by alias, rather than moving every call site.
**Rationale**: The source comment states the reason: an HTTP client must be able to send the contract without importing the plugin layer, and aliases keep existing `import AIPluginKit` call sites compiling. The cost is one extra name for each type.
**Approved**: pending

**Decision**: The related synchronization recipe's references still name an older plugin-layer path for the structs; the structs now live under the Core framework's `Stenographer` folder, and the Core struct also has an optional `removedConfigIds` field that recipe does not list.
**Rationale**: Recorded as an observed divergence from the sibling recipe, not corrected here, because this recipe covers only the aliases and the sibling recipe is owned separately.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`separation-of-concerns` passes because the file only maps names: the shape lives in Core, and sending and applying live elsewhere. `unit-test-coverage` is partial because `AIProviderConfigSyncTests` (`testRoundTrip`, `testDecodesMissingSelectionAsNil`) exercises the aliases through the plugin layer, but no test in the plugin layer's test target covers the optional `removedConfigIds` field (only the Core and Database test targets do) or asserts that the alias and the Core type are one type.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
