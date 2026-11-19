---
id: c9385bf6-3abc-486b-82b5-d57a62d86735
title: "Provider Model Picker"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-19
modified: 2026-11-19
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A provider popup above a model picker control, over the app's local provider configurations or the daemon's, where changing the provider resets the model to that provider's default."
platforms:
  - swift
  - macos
tags:
  - ai-plugins
  - model-selection
  - provider-selection
  - settings
depends-on:
  - b3059939-21f5-414b-82e4-edd11b192ae8
  - e886e448-6aa5-4359-979d-49fba713ab2a
related:
  - 3a3e4da0-e900-4281-a19c-e29cbd34cbab
references: []
approved-by: ""
approved-date: ""
---

# Provider Model Picker

## Overview

The provider model picker is the one control for choosing an AI provider
configuration and its model together. It is two settings rows: a provider
popup, and below it the model picker control
([adhsdk.ingredient.ai.plugins.model-picker](cookbook:b3059939-21f5-414b-82e4-edd11b192ae8)) that opens the popover
model chooser. It replaces the provider popups, the "Choose…"/"Try…" rows
and the free-text "Model" fields that the Coding Partner, AI Summaries, AI
Oversight, the Oversight findings window and the Sessions window each built
for themselves.

It works over a provider source, an interface with two implementations:

- **Local**: the app's plugin manager and its stored provider configurations
  ([adhsdk.ingredient.ai.plugins.plugin-runtime](cookbook:e886e448-6aa5-4359-979d-49fba713ab2a)).
- **Daemon**: the provider configurations the session daemon reports,
  resolving each one's template through an optional plugin manager so the
  model list and the default model's name can be shown. Without a plugin
  manager (Stenographer, which links the same code) the model row shows the
  stored name and its chooser lists nothing, but still opens.

The caller supplies the settings it binds to: the provider selection and a
function from a provider id to that provider's model setting (one shared
setting for summaries and oversight, one per configuration for the Partner).

Everywhere a model is stored, an empty string means the provider's default
model. A provider configuration's default model is set in the AI Providers
panel and is what the daemon receives as that configuration's model, so a
feature that stores an empty model follows it.

## Behavioral Requirements

### Provider Source

- **source-interface**: A provider source MUST list the selectable provider
  configurations (id and display name, in the source's order), and for a
  given configuration id MUST return its default model id, the display name
  for a model id, and a chooser context, each of which MAY be none.
- **local-source**: The local source MUST list the app's stored provider
  configurations, resolve each through the plugin manager, report a
  configuration's default model as its per-configuration model setting's
  resolved value (the stored model, else the template's default), and build
  the chooser context from the resolved plugin, template and the
  configuration's base URL and key.
- **daemon-source**: The daemon source MUST list the configurations the
  daemon reports, and report each one's default model as the model the
  daemon holds for it. With a plugin manager it MUST resolve each
  configuration's template through it to supply display names and a chooser
  context; with none, or when the template does not resolve, it MUST return
  the model id itself as the display name and a chooser context that lists
  no models.
- **daemon-source-async**: The daemon source MUST load the daemon's list off
  the UI thread and MUST tell the control when it has loaded, so the control
  rebuilds its popup and its model row; until then the popup lists only the
  leading choices and the stored selection.

### The Control

- **two-rows**: The control MUST lay out a provider popup row above a model
  picker control row.
- **configurable-labels**: The provider row's label MUST default to
  "Provider" and the model row's to "AI Model", and both MUST be set by the
  caller at construction.
- **leading-choices**: The popup MUST list the caller-supplied leading
  choices (such as "Default (CLI)" or "Default (Agent)") first,
  in the caller's order, then the source's configurations.
- **selection-binding**: The popup MUST select the entry whose id equals the
  provider selection setting's value, and choosing an entry MUST write its
  id to that setting.
- **stale-selection-kept**: While the source's list is not yet complete (a
  daemon that has not answered), a stored selection that the source does not
  list MUST still appear in the popup, selected, and the setting MUST NOT be
  rewritten, so loading the source late never silently changes it.
- **provider-change-resets-model**: Choosing a different provider MUST set
  the newly selected provider's model setting to `""`, so the model becomes
  that provider's default; for a leading choice no model setting is written.
  Re-choosing the provider already selected MUST NOT write either setting.
- **sentinel-disables-model**: With a leading choice selected, the model row
  MUST be disabled and read "Choose a Model".
- **model-display-rule**: The model row MUST show, in order of preference,
  the display name of the stored model when it is non-empty, else the display
  name of the provider configuration's default model, else "Choose a Model".
- **model-choice-binding**: A model chosen in the popover MUST be written to
  the selected provider's model setting.
- **external-change-refresh**: A change to the provider selection setting or
  to the selected provider's model setting made outside the control MUST
  update the popup and the model row.
- **chooser-opens-without-catalog**: With no plugin manager, the model row
  MUST stay enabled for a configuration (not a leading choice) and its
  chooser MUST open, listing nothing but the stored model.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

- **Corner radius**: Not applicable: the control draws no shape; the popup
  is the platform's.
- **Padding**: Each row uses the settings row insets of the panel it sits in;
  the two rows are separated by the panel's standard row spacing.
- **Font**: Both labels use the theme's body font, like every settings row
  label; the model row's name is as the model picker control draws it.
- **Background**: None of its own; the panel's background shows through.
- **Foreground/Text**: Labels in the primary text color; a disabled model row
  is dimmed by the platform.
- **Border**: None beyond the platform popup's own.
- **Shadow**: Not applicable: no shadow is drawn.
- **Min/Max size**: The popup grows to its widest entry and the row to the
  panel's width; no other constraint.

## States

| State | Appearance change |
|-------|------------------|
| Default | Popup shows the selected configuration; model row shows the stored model, else the configuration's default. |
| Leading choice selected | Popup shows the sentinel; model row disabled, reading "Choose a Model". |
| No model known | Model row reads "Choose a Model"; enabled for a configuration. |
| Loading (daemon) | Popup lists the leading choices and the stored selection; it fills in when the daemon's list arrives. |
| Disabled | The caller disabled the control: popup and model row both disabled. |
| Pressed | The popup and model row show their platform pressed states. |
| Focused | The platform focus ring on the popup or the model row's buttons. |

## Accessibility

- **Role/trait**: A pop-up button for the provider; the model row's roles are
  the model picker control's.
- **Label requirements**: The popup's accessibility label MUST be the provider
  row's label, so a caller's custom label ("Summaries provider") is what a
  screen reader says.
- **Announce state changes**: A provider change updates the model row's name,
  which the platform reports as a value change of its name button.
- **Minimum tap target**: Pointer-driven controls on macOS; the platform popup
  meets the platform's own size.
- **Contrast**: Colors come from theme roles; the theme decides whether they
  clear 4.5:1.

Keyboard: Tab moves from the popup to the model row's caret and name; Space
opens the popup.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| provider-model-picker-001 | configurable-labels | Construct with labels "Summaries provider" and "Summaries model" | The rows read those labels |
| provider-model-picker-002 | leading-choices | Leading choice "Default (CLI)"; source lists configs `a`, `b` | The popup lists "Default (CLI)", `a`, `b` in that order |
| provider-model-picker-003 | provider-change-resets-model | Selection `a`; `b`'s model setting is `m9`; choose `b` | The selection setting is `b`; `b`'s model setting is `""` |
| provider-model-picker-004 | provider-change-resets-model | Selection `a`; choose `a` again | Neither setting is written |
| provider-model-picker-005 | sentinel-disables-model, provider-change-resets-model | Selection `a`; choose the leading choice | The selection is the sentinel's id; no model setting is written; the model row is disabled and reads "Choose a Model" |
| provider-model-picker-006 | model-display-rule | Selected `a`; its model setting is `m2` (display "Model Two"); default `m1` | The model row reads "Model Two" |
| provider-model-picker-007 | model-display-rule | Selected `a`; its model setting is `""`; default `m1` (display "Model One") | The model row reads "Model One" |
| provider-model-picker-008 | model-display-rule | Selected `a`; model setting `""`; no default | The model row reads "Choose a Model" |
| provider-model-picker-009 | model-choice-binding | Selected `a`; the chooser reports `m3` | `a`'s model setting is `m3` |
| provider-model-picker-010 | stale-selection-kept | Selection `gone`, which the source does not list | The popup shows `gone` selected; the setting is unchanged |
| provider-model-picker-011 | daemon-source, chooser-opens-without-catalog | Daemon source with no plugin manager; config `d1` with model `qwen3` | The model row reads `qwen3`, is enabled, and its chooser opens listing only `qwen3` |
| provider-model-picker-012 | external-change-refresh | The selected provider's model setting changes to `m4` elsewhere | The model row shows `m4`'s display name |
| provider-model-picker-013 | local-source | Local source; configuration `c1` with an empty stored model and a template default `m1` | Its default model is `m1` |
| provider-model-picker-014 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

## Edge Cases

- The daemon is not running: the daemon source lists nothing; the popup keeps
  the leading choices and the stored selection, and the model row shows the
  stored model's id.
- A configuration whose template no longer resolves: it stays listed under
  its name; its model row shows the stored id or "Choose a Model", and its
  chooser lists nothing.
- Two controls bound to the same settings (two windows open): each updates
  from the other's writes (**external-change-refresh**).
- No leading choices and no configurations: the popup is empty and the model
  row disabled.
- A model setting shared by several providers (summaries and oversight): a
  provider change still writes `""` to it, which is the new provider's
  default.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Provider source | provider source | — (required) | Local or daemon. |
| Provider selection | text setting | — (required) | The selected provider id, or a leading choice's id. |
| Model setting | function from provider id to text setting | — (required) | The model setting for a provider; `""` means the provider's default. |
| Leading choices | list of (id, title) | empty | Sentinel entries listed first. |
| Provider label | text | "Provider" | The provider row's label. |
| Model label | text | "AI Model" | The model row's label. |
| Plugin manager (daemon source) | optional plugin manager | none | Resolves templates for display names and the chooser's list. |

## Deep Linking

Not applicable: the control is two settings rows, not a navigable screen.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded literal) | `Provider` | The provider row's default label |
| (none — hardcoded literal) | `AI Model` | The model row's default label |
| (none — hardcoded literal) | `Choose a Model` | The model row with no model, or with a leading choice selected |

The leading choices' titles are the caller's.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the control animates nothing of its own. |
| Increase Contrast | Theme roles; resolved by the theme layer. |
| Differentiate Without Color | Not applicable: no state is shown by color; a disabled model row reads "Choose a Model". |

## Feature Flags

Not applicable: no flag gates the control.

## Analytics

Not applicable: the control records no event.

## Privacy

- **Data collected**: None of its own. The local source reads a
  configuration's API key only to build the chooser context.
- **Storage**: The provider selection and the model setting, both
  caller-supplied, non-secret settings.
- **Transmission**: The daemon source asks the local daemon over loopback for
  its provider list; nothing leaves the machine except what the chooser
  fetches (see the model picker).
- **Retention**: The settings persist until changed; the control keeps no
  copy.
- **Security-violation handling**: Not applicable: the control has no
  detection surface.

## Logging

The daemon source logs a failed list request (the error only, never a key)
through the daemon client's own logger; the control itself logs nothing.

## Platform Notes

- **SwiftUI**: A `Form` section with a `Picker` bound to the selection
  (`.pickerStyle(.menu)`) and the model control below it; `.onChange(of:
  selection)` writes `""` to the new provider's model setting when the value
  differs, and `.disabled` drives the model row for a sentinel. The source
  becomes an `@Observable` model loading the daemon list in a `.task`.
- **Compose**: An `ExposedDropdownMenuBox` for the provider and the model
  control's `Row` below; a `ViewModel` exposes the source as a `StateFlow`, and
  the selection handler writes the empty model through the repository only
  when the id changes.
- **React/Web**: A `<select>` (or a listbox component) with
  `aria-labelledby` on its label, and the model control below; `onChange`
  writes the selection and resets the model setting when the id differs. The
  daemon source is a fetch in a data hook with a loading state that keeps the
  stored selection listed.
- **AppKit/UIKit** (source platform):
  `packages/apple/AgenticDeveloperHubSDK/macOS/Features/AIPlugins/Settings/ProviderModelPickerView.swift`
  holds `ProviderModelPickerView` (an `NSView` of two rows: an `NSPopUpButton`
  and an `AIModelPickerControl`);
  `ProviderRegistrySource.swift` beside it holds the source protocol,
  `ProviderRegistrySource` (named apart from AIPluginKit's
  `ProviderModelSource`, which fetches one provider's catalog), with
  `isAuthoritative` saying whether the list is complete, and its two
  implementations, `LocalProviderRegistrySource` and
  `DaemonProviderRegistrySource`. Local reads `AIPluginManager` and
  `UserSettings.aiProviderConfigurations` and resolves the default through
  `AIProviderConfigStore.modelSetting(config:template:)`; daemon calls
  `StenographerService.aiProviderConfigs()` and takes an optional
  `AIPluginManager`. Settings are `UserSetting<String>` for the selection and
  `modelSetting: (String) -> UserSetting<String>`. It replaces
  `LLMPickerView` and `DaemonProviderPickerView`, which are deleted. Callers:
  `PartnerGeneralSettingsViewController`, `AISummariesSettingsPanel`,
  `AIOversightSettingsPanel`, `OversightFindingsViewController` and
  `SessionsWindowController`; the Sessions, Conversations and Oversight
  coordinators take `pluginManager: AIPluginManager? = nil`, which the Kitchen
  passes and Stenographer does not. A UIKit port would use a `UIButton` with a
  `UIMenu` for the popup.
- **WinUI 3**: A `StackPanel` of two rows: a `ComboBox` (`ItemsSource` bound to
  an `ObservableCollection` of the leading choices then the configurations,
  `SelectedValuePath="Id"`, `SelectedValue` two-way bound to the selection) with
  `AutomationProperties.Name` set to the provider label, and the model control
  below. The view model's selection setter writes `""` to the new provider's
  model only when the id differs, and raises `PropertyChanged` for the model
  row's name. Load the daemon list with an `async` call off the UI thread and
  marshal back through `DispatcherQueue.TryEnqueue`; set the model row's
  `IsEnabled` false for a sentinel.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/AIPlugins/Settings/ProviderModelPickerView.swift` | confirmed (1.0.0) |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/AIPlugins/Settings/ProviderRegistrySource.swift` | confirmed (1.0.0) |

## Design Decisions

- **Decision**: Changing the provider sets the model setting to `""`, the
  new provider's default, instead of keeping the old model id.
  **Rationale**: A model id is meaningful only to the provider that serves it;
  carrying it across a provider change sends a request the new provider
  rejects. `""` already means the provider's default in every feature, and
  the default is set per configuration in the AI Providers panel.
  **Approved**: pending
- **Decision**: One control over a provider source with local and daemon
  implementations, instead of a picker per registry.
  **Rationale**: The two pickers had drifted (one had a model chooser, the
  other a free-text field); a single control with the registry behind an
  interface keeps every panel's provider and model choice the same.
  **Approved**: pending
- **Decision**: The daemon source takes an optional plugin manager.
  **Rationale**: The Kitchen has one and can show model lists and names;
  Stenographer links the same code without one, and its panels must still
  show and set a provider and the stored model.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | accessibility |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

`native-controls-preference` rests on the platform pop-up button and the
model picker control; `keyboard-navigable` and `screen-reader-support` on the
popup's tab stop and its label (**configurable-labels**). `data-integrity`
passes because a provider change never carries a model id to a provider that
does not serve it (**provider-change-resets-model**) and a stored selection
the source does not list is kept (**stale-selection-kept**).
`separation-of-concerns` passes because registries sit behind the provider
source and settings are injected. `unit-test-coverage` is `failed` until the
provider-change, display and source rules have tests; the code is planned.
`no-hardcoded-strings` fails because the default labels are English
literals.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-19 | Mike Fullerton | Initial creation, ahead of the code: the combined provider and model control and its local and daemon provider sources |
