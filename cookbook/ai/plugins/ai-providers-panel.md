---
id: d3863175-a089-426d-982c-d489965593ac
title: "AI Providers Panel"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-19
modified: 2026-11-20
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The settings panel where a person adds, edits and removes AI provider configurations: one sidebar row per configuration, its editor, and a Test Chat pinned to it."
platforms:
  - swift
  - macos
tags:
  - ai-plugins
  - settings
  - provider-configuration
depends-on:
  - b3059939-21f5-414b-82e4-edd11b192ae8
  - 2e0bf51e-905d-476d-9c0c-48465174ba59
  - e886e448-6aa5-4359-979d-49fba713ab2a
related:
  - e886e448-6aa5-4359-979d-49fba713ab2a
  - c9385bf6-3abc-486b-82b5-d57a62d86735
references: []
approved-by: ""
approved-date: ""
---

# AI Providers Panel
## Overview

The AI Providers panel is the settings panel where a person edits the
provider configurations the plugin runtime
([adhsdk.ingredient.ai.plugins.plugin-runtime](cookbook:e886e448-6aa5-4359-979d-49fba713ab2a))
models and stores. The plugins coordinator hands it back as its settings
panel; its title is "AI Connections" and its sidebar is headed
"Connections".

Each configuration is one sidebar row. Selecting a row shows that
configuration's editor: a Name row, one row per field of the configuration's
template, and a default model row, followed by a Test Chat pinned to the
configuration. A + button adds a configuration from the provider picker and
a − button removes the selected one after a confirmation.

The editor sets the configuration's default model through the model picker
control
([adhsdk.ingredient.ai.plugins.model-picker](cookbook:b3059939-21f5-414b-82e4-edd11b192ae8)),
and its secret fields use the secure text row with reveal
([adhsdk.ingredient.ui.settings.rows.secure-text-edit-view](cookbook:2e0bf51e-905d-476d-9c0c-48465174ba59)).
Every other place that chooses a provider and a model uses the combined
provider model picker
([adhsdk.ingredient.ai.plugins.provider-model-picker](cookbook:c9385bf6-3abc-486b-82b5-d57a62d86735)),
and an empty stored model there means the default model set here.
## Behavioral Requirements

### Panel and List

- **providers-panel-identity**: The panel MUST be titled "AI Connections"
  and its sidebar headed "Connections", and it MUST list one row per
  provider configuration, in the order of the provider-configurations list.
- **providers-panel-load-failures**: When loading the plugins reports one or
  more failures, the panel MUST append one more row after the configurations,
  titled "1 plugin failed to load" or "<n> plugins failed to load", whose
  page lists each failure as "<plugin name>: <message>". With no failures
  there MUST be no such row.
- **providers-panel-add**: The + button MUST open the provider picker over
  the panel's window, listing every available template sorted
  case-insensitively by provider, then LLM, then config type. Choosing a
  template MUST append a configuration named after the template's display
  name (made unique among the configurations), seeded from the template
  (`config-store-seed` in the plugin runtime), persisted, and selected.
- **providers-panel-remove-confirm**: The − button MUST be enabled only
  while a configuration is selected. Pressing it MUST ask "Delete
  “<name>”?" with the explanation "This removes the configuration and its
  stored settings, including any API key.", a destructive "Delete" button
  and "Cancel" (as a sheet on the panel's window, or a modal alert when there
  is none); with nothing selected it MUST refuse with the platform's refusal
  feedback instead.
- **providers-panel-remove-clears-values**: Deleting a configuration MUST
  clear every stored field value of that configuration, secrets included,
  and its stored model, using the template's fields, or the plugin's shared fields when the
  template no longer resolves, so a stored key is removed either way. It
  MUST then drop the configuration from the list, persist the list, clear
  the selected-configuration-id setting when it named that configuration,
  and select the row before it, or the first row when it was first.
- **providers-panel-keeps-panels**: Adding or removing a configuration MUST
  keep the existing editors of the configurations it did not touch, so their
  in-progress edits survive.
- **providers-panel-rename**: Editing the Name row MUST rename the
  configuration to the trimmed text, made unique among the other
  configurations; empty or unchanged text MUST be ignored. The sidebar row
  and the editor's Name row MUST then show the stored name.

### Configuration Editor

- **providers-panel-subtitle**: Each configuration's panel descriptor MUST
  carry the subtitle "Provider - LLM - Config type", built from the
  template's resolved provider, resolved LLM and resolved config type joined
  by " - ", with empty parts dropped (no subtitle when all three are empty),
  and MUST update it when the configuration's template changes.
- **providers-editor-title**: The configuration editor's title MUST read
  "Provider, LLM, Config type", built from the same three parts joined by
  ", ", with empty parts dropped, and MUST read the configuration's name
  when that leaves nothing.
- **providers-editor-default-model-row**: The editor MUST show a default
  model row: a model picker control labelled "Default Model", bound to the
  per-configuration model setting, whose name is the stored model when
  non-empty, else the template's resolved default model, and whose chosen
  model is written to that setting. This is the model the configuration
  resolves to (`config-store-model-default` in
  [adhsdk.ingredient.ai.plugins.plugin-runtime](cookbook:e886e448-6aa5-4359-979d-49fba713ab2a))
  and the model a feature gets when it stores `""`. The row MUST refresh
  when that setting changes elsewhere, such as from the Test Chat, and MUST
  rebuild what its chooser lists (and the name's display lookup) when a
  connection field it reads changes, such as the base URL or the API key.
- **providers-editor-no-free-text-model**: The editor MUST NOT offer a
  free-text model field; the default model row is the only way the editor
  sets the model.
- **providers-editor-untitled-connection-group**: The editor's connection
  field group (the Name row, the template fields and the default model row)
  MUST be shown with no group title.
- **providers-editor-secret-reveal**: Every secret field in the editor MUST
  use the secure text row with reveal
  ([adhsdk.ingredient.ui.settings.rows.secure-text-edit-view](cookbook:2e0bf51e-905d-476d-9c0c-48465174ba59)),
  whose requirements (`stored-secret-shows-as-dots`,
  `trailing-accessory-buttons` and the `reobscure-on-*` rules) govern how the
  field shows, copies and re-obscures the secret.
- **providers-test-chat-model-only**: The editor's Test Chat MUST pin its
  configuration: it MUST hide the provider choice and show only the model
  row, whose Choose Model action opens the popover model chooser for that
  configuration.
## Appearance

- **Sidebar**: headed "Connections", one row per configuration titled with
  the configuration's name, with the subtitle "Provider - LLM - Config type"
  (see **providers-panel-subtitle**), and a trailing load-failures row when
  plugins failed to load (see **providers-panel-load-failures**). Below the
  list, a footer with + ("Add a provider") and − ("Remove the selected
  provider") buttons.
- **Editor**: a title line reading "Provider, LLM, Config type" (the
  configuration's name when all three parts are empty), then one untitled
  group holding the Name row, one row per template field in the plugin's
  order (secret fields as the secure text row), and the "Default Model"
  model picker row (see **providers-editor-title**,
  **providers-editor-untitled-connection-group** and
  **providers-editor-default-model-row**). The editor is sized to its
  content.
- **Test Chat**: a card captioned "Test Chat" below the editor, at least
  240 points tall, showing the model row with its "Choose Model…" button and
  no provider choice (see **providers-test-chat-model-only**).
## States

| State | What shows |
|-------|------------|
| Template resolves | The Name row, one row per template field, and the "Default Model" row. |
| Template does not resolve | The Name row only: no field rows and no "Default Model" row; the title falls back to the configuration's name. |
| Stored model empty | The "Default Model" row names the template's resolved default model. |
| No model to show | The "Default Model" row reads "Choose a Model". |
| Secret stored | The secret field shows dots, per the secure text row. |
| Nothing selected | The − button is disabled. |
| Plugins failed to load | A load-failures row follows the configurations. |
## Accessibility

- The secure text row's copy button is labelled "Copy" and its eye button
  "Show" or "Hide" by state; the field, copy and eye buttons follow each
  other in the key-view loop (per the secure text row).
- The "Default Model" row's caret is described as "Choose a model", and its
  name button takes the row's label as its accessibility title element.
- The editor's title carries the accessibility identifier
  `providers.editor.title`; the model picker's caret and name carry
  `ai-model-picker.caret` and `ai-model-picker.name`, the Test Chat's
  Choose Model button `ai-chat.choose-model`, and the footer's buttons take
  the prefix `providers.add-remove`.
- The popover model chooser is driven from its filter field with up, down,
  Return and Escape.
## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ai-providers-panel-001 | providers-panel-subtitle, providers-editor-title | Template with provider "Acme", LLM "Chat", config type "API key" | The subtitle is "Acme - Chat - API key" and the editor title is "Acme, Chat, API key" |
| ai-providers-panel-002 | providers-panel-subtitle, providers-editor-title | Template with provider "Acme", empty LLM, config type "Local" | The subtitle is "Acme - Local" and the editor title is "Acme, Local" |
| ai-providers-panel-003 | providers-editor-default-model-row | Configuration with stored model ""; template default "m1" | The "Default Model" row names "m1"; choosing "m2" writes "m2" to `aiplugin.config.<id>.model` and the row names "m2" |
| ai-providers-panel-004 | providers-editor-no-free-text-model, providers-editor-untitled-connection-group | Open a configuration's editor | No free-text model field is present; the connection group has no title; its first row is "Name" |
| ai-providers-panel-005 | providers-editor-secret-reveal | A configuration with a stored API key "sk-123" | The key field shows six dots (one per character, per the secure text row's `stored-secret-shows-as-dots`) with copy and eye buttons; a non-secret field such as Base URL is a plain text row |
| ai-providers-panel-006 | providers-test-chat-model-only | Open the editor's Test Chat | Only the model row shows; its Choose Model action opens the popover chooser for this configuration |
| ai-providers-panel-007 | providers-panel-add | Add the template with display name "Acme" twice | Two configurations, named "Acme" and "Acme 2"; the first holds the template's seeded field values |
| ai-providers-panel-008 | providers-panel-remove-clears-values | One configuration, named by the selected-configuration-id setting; delete it | The list is empty and the selected-configuration-id setting is "" |
| ai-providers-panel-009 | providers-panel-load-failures | One load failure, then two | The row is titled "1 plugin failed to load", then "2 plugins failed to load" |
## Edge Cases

- A configuration whose template no longer resolves (the plugin was removed
  or the template renamed): the editor shows the Name row only and is titled
  with the configuration's name; deleting it still clears its stored key
  through the plugin's shared fields (**providers-panel-remove-clears-values**).
- A rename to empty or whitespace-only text: ignored; the stored name stays
  (**providers-panel-rename**).
- A rename to a name another configuration already has: the name is made
  unique (**providers-panel-rename**).
- The Test Chat chooses a model: it writes the same model setting the
  "Default Model" row shows, and the row refreshes
  (**providers-editor-default-model-row**).
- The − button pressed with nothing selected: the panel refuses with the
  platform's refusal feedback and asks nothing
  (**providers-panel-remove-confirm**).
- The deleted configuration was the first row: selection moves to the new
  first row; when it was the last configuration, nothing is selected and −
  is disabled.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Plugin manager | plugin manager | — (required) | Supplies the available templates, each template's fields and the plugin load failures. |
| `"aiplugin.configurations"` | list of provider configurations (settings key) | `[]` | The configurations the panel lists, adds to, renames and removes from (owned by the plugin runtime). |
| Per-configuration field and model settings | text settings | the template's defaults | What each editor row reads and writes, through the plugin runtime's configuration store. |
## Deep Linking

Not applicable: the panel has no route of its own. A host can select a
configuration by name programmatically (for scripting and UI tests), but no
URL addresses it.
## Localization

The panel routes none of its user-facing strings through a localization
mechanism; they are hardcoded English literals:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded literal) | `AI Connections` | The panel's title |
| (none — hardcoded literal) | `Connections` | The sidebar's heading |
| (none — hardcoded literal) | `Add a provider` / `Remove the selected provider` | The footer buttons' tooltips |
| (none — hardcoded literal) | `Delete “<name>”?` | The delete confirmation's message |
| (none — hardcoded literal) | `This removes the configuration and its stored settings, including any API key.` | The delete confirmation's explanation |
| (none — hardcoded literal) | `Delete` / `Cancel` | The delete confirmation's buttons |
| (none — hardcoded literal) | `1 plugin failed to load` / `<n> plugins failed to load` | The load-failures row's title |
| (none — hardcoded literal) | `Name` | The editor's name row label |
| (none — hardcoded literal) | `Default Model` | The editor's default model row label |
| (none — hardcoded literal) | `<provider> - <LLM> - <config type>` | A configuration panel's subtitle; the separator is a literal |
| (none — hardcoded literal) | `<provider>, <LLM>, <config type>` | The configuration editor's title; the `, ` separator is a literal |
| (none — hardcoded literal) | `Choose Model…` | The Test Chat's button that opens the popover model chooser |
| (none — hardcoded literal) | `Test Chat` | The caption over the Test Chat card under a configuration's editor |
## Accessibility Options

Not applicable: the panel responds to no display accommodation (Reduce
Motion, Increase Contrast, Differentiate Without Color) in its own code.
## Feature Flags

Not applicable: no flag gates the panel.
## Analytics

Not applicable: the panel records no analytics or telemetry event.
## Privacy

- **Data collected**: The field values a person types into a configuration,
  including API keys.
- **Storage**: None of the panel's own. Every value is written through the
  plugin runtime's configuration store, which keeps secret fields in secure
  storage (see the plugin runtime's Privacy).
- **Transmission**: The panel sends nothing itself. The Test Chat sends the
  person's messages to the configured provider, and the model chooser
  fetches the provider's model list with the configuration's key.
- **Retention**: Values persist until the configuration is deleted;
  deleting it clears its stored field values, secrets included, and its
  stored model (**providers-panel-remove-clears-values**).
- **Security-violation handling**: Not applicable: the panel has no
  detection surface.
## Logging

Not applicable: the panel logs nothing of its own; plugin load failures are
shown in the panel rather than logged by it.
## Platform Notes

- **Apple implementation (AppKit)**: The panel lives in
  `Features/AIPlugins/Settings/`. `AIPanelViewController`
  (`AISettingsViewPanelController.swift`) is a
  `SettingsPanelSplitViewController` whose footer is an
  `AddRemoveFooterView`; the + button presents `ProviderPicker` over the
  window, − confirms with an `NSAlert` (a sheet when the panel has a
  window), and each configuration's page is a private
  `ProviderConfigPanelViewController` reused by configuration id.
  `LLMProvidersListViewModel` owns the list, add, rename and remove;
  `PluginLoadFailuresPanel` is the trailing failures page, fed by
  `AIPluginManager.loadAllPlugins().failures`. The editor is the AppKit view
  `LLMProviderEditorView` (`LLMProvidersView.swift`), built from
  ComposableSettings rows: a secret field is a
  `ComposableSettings.SecureTextEditView`, any other field a
  `ComposableSettings.TextEditView`, and the connection group is a
  `ComposableSettings.GroupView` with an empty header view. The default
  model row is an `AIModelPickerControl` labelled "Default Model" over
  `AIProviderConfigStore.modelSetting(config:template:)`, refreshed by a
  `UserSettingObserver` on that setting. The subtitle and title come from
  `ProviderConfigTitles` (`template.resolvedProvider`, `resolvedLLM`,
  `resolvedConfigType`), and the subtitle is set on the panel's
  `descriptor.subtitle`. The Test Chat is
  `AIChatViewController(pluginManager:configuration:pinsConfiguration: true)`
  inside a themed card, whose "Choose Model…" button presents
  `ModelChooser` in a popover. Deleting calls
  `AIProviderConfigStore.clearStoredValues(config:fields:)`, which writes
  `""` to each field setting and the model setting; a secure setting's
  value lives in the Keychain.
- **SwiftUI**: A SwiftUI port would keep the list model as an observable
  object and host `ComposableSettings.SecureTextEditView` and
  `AIModelPickerControl` through `NSViewRepresentable`, or port those rows.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/AIPlugins/Settings/LLMProvidersView.swift` | confirmed (1.0.1) |
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/AIPlugins/Settings/LLMProvidersListViewModel.swift` | confirmed (1.0.1) |
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/AIPlugins/Settings/AISettingsViewPanelController.swift` | confirmed (1.0.1) |
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/AIPlugins/Settings/PluginLoadFailuresPanel.swift` | confirmed (1.0.1) |

## Design Decisions

- **Decision**: Reuse each configuration's editor across an add or a remove
  instead of rebuilding every page.
  **Rationale**: Rebuilding would discard the in-progress edits of
  configurations the change never touched.
  **Approved**: pending
- **Decision**: When a configuration's template no longer resolves, clear
  its stored values through the plugin's shared field list.
  **Rationale**: The delete confirmation promises to remove "any API key";
  without the fallback, a configuration whose plugin was removed or whose
  template was renamed would leave its key in secure storage.
  **Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

screen-reader-support passes because the panel's icon-only controls carry
labels: the secure text row's copy button reads "Copy" and its eye button
"Show" or "Hide", the model picker's caret is described as "Choose a model",
and its name button takes the row's label as its title element.
keyboard-navigable passes because every control in the editor and the Test
Chat is a standard field or button, the secure text row chains its field to
the copy and eye buttons in the key-view loop, and the popover model chooser
is driven from its filter field by up, down, Return and Escape.
separation-of-concerns passes because the panel reaches configuration
storage only through the plugin runtime's configuration store and the
provider-configurations setting. unit-test-coverage is partial: vectors
001–005 and 007–009 trace to `ProviderEditorTests`,
`LLMProvidersListViewModelTests` and `PluginLoadFailuresPanelTests`, while
the Test Chat (006), the delete confirmation and rename have no tests.
secure-storage passes because secret fields are written through the
configuration store's secure settings and cleared on delete.
no-hardcoded-strings fails because the strings under Localization are
English literals.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-20 | Mike Fullerton | The default model row rebuilds its chooser context when a connection field changes. |
| 1.0.0 | 2026-11-19 | Mike Fullerton | Initial creation: the AI Providers panel, moved out of the plugin runtime, with its list, add, rename and remove behavior |
