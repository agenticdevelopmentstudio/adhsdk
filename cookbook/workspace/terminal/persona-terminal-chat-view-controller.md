---
id: 32481824-a0e2-450f-b92b-e5e5861cd510
title: "Persona Terminal Chat View Controller"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A pane that chats with an AI persona, picked per pane with a provider, model and instructions, which works the terminal only through the tab's Terminal Chat."
platforms:
  - swift
  - macos
tags:
  - terminal
  - chat
  - ai-persona
  - pane-settings
depends-on: []
related:
  - 2cd6ffc0-e9db-425b-99ba-eb826ffff118
references:
  - https://developer.apple.com/documentation/appkit/nsviewcontroller
  - https://developer.apple.com/documentation/appkit/nspopupbutton
  - https://developer.apple.com/documentation/swift/mainactor
approved-by: ""
approved-date: ""
---

# Persona Terminal Chat View Controller

## Overview

`PersonaTerminalChatViewController` is a chat pane with an AI persona that can
work the user's terminal. It never touches the terminal directly: it reaches it
by way of the Terminal Chat in the same tab ("the Terminal Chat" is the first
one in that tab). When that Terminal Chat is connected to a private terminal,
the persona only ever sees the terminal's privacy words, never the real ones
(the source's description of the Terminal Chat's behavior; the masking is not
done in this file).

The persona runs on one of the LLM providers configured in Settings, chosen per
pane along with a model and the persona's instructions. The source calls the
feature experimental and deliberately narrow, like the Terminal Chat itself.

The controller:

- builds a `LocalChatSession` whose plugin, context and tools are looked up at
  the moment of each turn, so a change in the pane's settings applies to the next
  message with no rebuild;
- shows a `ChatView` filling a 360 by 500 themed container, with a status line
  that says why the chat cannot yet work;
- offers four rows in the pane's options sheet (connect toggle, LLM provider,
  model, persona) through `PaneOptionsProviding`, and stores the choices in the
  pane's state store;
- cancels its model fetch and closes its session when the pane is discarded.

The chat view, session, view model, plugin manager, provider resolver and the
Terminal Chat are other components; this recipe covers the wiring, the
settings and the status logic in this controller.

## Behavioral Requirements

### Construction and session

- **init-takes-dependencies**: The initializer MUST take a pane state store and an
  AI plugin manager, and MAY take browser tools (`nil` by default) and a pane id
  (`nil` by default).
- **coder-init-unavailable**: Creating the controller from a coder MUST be
  unavailable.
- **session-built-at-init**: The initializer MUST create one `LocalChatSession` and
  one `AIChatViewModel` over it.
- **settings-read-per-turn**: The session's plugin resolver and context builder MUST
  read the pane's settings when each turn runs, so a provider, model or persona
  changed in Settings applies to the next message without rebuilding the session.
- **context-fallback-when-released**: If the controller is gone when a turn builds
  its context, the context MUST be the history with an empty model and an empty
  plugin configuration.
- **tools-composite**: The session's tool source MUST be a composite of the Terminal
  Chat tool source followed by the browser tools when they were given.
- **tools-without-browser**: With no browser tools the composite MUST hold only the
  Terminal Chat tools.
- **tool-caller-is-pane-id**: The session's tool caller MUST be the pane id's UUID
  string, so "the active pane" resolves to the pane this chat sits in; with no
  pane id it MUST be `nil`.
- **main-actor-isolated**: The controller MUST run on the main actor, and its
  session closures MUST hop to the main actor to read settings.

### View

- **view-container**: `loadView` MUST create a themed container with the window
  background role and a 360 by 500 frame.
- **view-chat-fills**: The `ChatView` MUST be pinned to all four edges of the
  container.
- **view-interrupt-enabled**: The chat view's interrupt MUST be enabled.
- **status-applied-on-load**: `loadView` MUST apply the status once the view exists.
- **status-applied-on-appear**: `viewDidAppear` MUST apply the status again, because
  the Terminal Chat can only be found once the pane is in the tree.

### Status

- **status-no-provider**: When no provider configuration is chosen (or the chosen
  one no longer exists in Settings), the composer MUST be disabled and the status
  MUST read `Choose an LLM provider in this pane's Settings`.
- **status-not-connected**: When a provider is chosen and Connect is off, the
  composer MUST be enabled and the status MUST read
  `Not connected — turn on Connect to Terminal Chat in this pane's Settings`.
- **status-no-terminal-chat**: When a provider is chosen, Connect is on and the tab
  has no Terminal Chat, the status MUST read
  `No Terminal Chat in this tab to connect to`.
- **status-clear-when-ready**: When a provider is chosen, Connect is on and a
  Terminal Chat is found, the status MUST be cleared.
- **status-checked-in-order**: The cases MUST be checked in the order no provider,
  not connected, no Terminal Chat.
- **status-no-icon**: The status MUST be set with no icon.
- **status-before-view-noop**: Applying the status before the view is loaded MUST do
  nothing.

### Pane settings

- **settings-keys**: The pane's choices MUST be kept in the pane state store under the
  keys `connected`, `configurationID`, `model` and `persona`.
- **connect-stored-as-flag**: Connect MUST be on exactly when `connected` equals `1`,
  and turning it off MUST remove the key (store `nil`) rather than store `0`.
- **configuration-lookup**: The chosen configuration MUST be the entry of the user
  settings' AI provider configurations whose id string equals `configurationID`;
  a missing key or an id that matches no entry means no configuration.
- **model-override-optional**: A stored `model` MUST override the provider's own
  model; `nil` means the provider's.
- **persona-default**: With no stored `persona` the persona MUST be the default text
  below.
- **persona-default-text**: The default persona MUST be: "You are a capable, careful
  shell assistant working alongside the user in their macOS terminal. Use
  run_terminal_command to look around and to do what the user asks, and report
  back briefly. Never run anything destructive or irreversible — deleting files,
  force-pushing, changing system settings — unless the user has explicitly asked
  for that exact thing. If a command is still running, use
  wait_for_terminal_output or interrupt_terminal."

### Turns

- **plugin-prompted-tools**: The plugin for a turn MUST be the chosen provider's
  plugin loaded by its plugin identifier, wrapped in `PromptedToolCallingPlugin`,
  because no provider plugin sends tool definitions natively and the Claude Code
  CLI cannot take custom ones.
- **plugin-nil-without-configuration**: With no configuration the plugin resolver MUST
  return `nil`.
- **plugin-load-failure-silent**: If loading the plugin fails, the resolver MUST return `nil` through `try?` with no log, and the controller's status MUST NOT change; `LocalChatSession` then reports the `nil` plugin as a failed turn with the message `No AI provider is configured.`, so the user sees that message rather than the cause.
- **context-values**: With a configuration that resolves, the context MUST carry the
  resolved provider values plus `model` set to the model override or else the
  resolved model.
- **context-model-name**: The context's model MUST be that same model, and the
  system prompt MUST be the persona.
- **context-unresolved**: With no configuration, or one the resolver cannot resolve,
  the context MUST carry the history, an empty model, the persona and an empty
  configuration.
- **terminal-chat-lookup**: The connected Terminal Chat MUST be `nil` unless Connect is
  on; otherwise it MUST be the session of the first `TerminalChatViewController`
  among the tab's pane contents, and `nil` when there is none.

### Options rows

- **options-rows**: `makePaneOptionRows` MUST return four rows, in order: the connect
  toggle, the LLM provider picker, the model picker and the persona field.
- **options-connect-title**: The connect toggle MUST be titled
  `Connect to Terminal Chat`, reflect the stored flag, and carry the accessibility
  id `personaTerminalChat.options.connect`.
- **options-connect-change**: Changing the toggle MUST store the flag and re-apply the
  status.
- **options-provider-list**: The provider picker MUST list `None` first (no stored
  id), then one item per configured provider named by its name and carrying its
  id string, select the stored one if it still exists, and carry the accessibility
  id `personaTerminalChat.options.provider`.
- **options-labels**: The rows MUST be labelled `LLM provider`, `Model` and
  `Persona` with a label above the control, vertically stacked, leading-aligned,
  4 points apart.
- **provider-chosen**: Choosing a provider MUST store its id (or remove the key for
  `None`), clear the model override, refill the model list and re-apply the status.
- **model-chosen**: Choosing a model MUST store the item's value, or remove the key
  for the first item (the provider default).
- **persona-edited**: Committing the persona field MUST store the trimmed text, and
  MUST remove the key when the trimmed text is empty or equals the default
  persona.
- **persona-commit-on-end-editing**: The persona field MUST commit when it loses focus
  as well as on Return, so closing the sheet does not discard an edit.
- **persona-field-shape**: The persona field MUST wrap words, allow several lines, be
  at least 360 points wide, 110 points high, and carry the accessibility id
  `personaTerminalChat.options.persona`.
- **model-picker-id**: The model picker MUST carry the accessibility id
  `personaTerminalChat.options.model`.

### Model list

- **models-default-item**: The model picker's first item MUST be `Provider default (<model>)`
  when the provider's model is known, else `Provider default`, and carry no value.
- **models-from-template**: The list MUST be filled from the provider template's models,
  after the default item.
- **models-keeps-override**: A stored override that is not in the list MUST be
  appended so it stays selectable, and the picker MUST select it; otherwise it
  MUST select the default item.
- **models-no-provider**: With no configuration, no template or no resolved values,
  the picker MUST hold only the default item (no model name).
- **models-live-fetch**: For a provider whose plugin identifier ends in `.openai-compatible` or `.openai`, the controller MUST
  also fetch the provider's model list from its base URL (empty string when
  unset) and API key, and replace the list with it when the fetch finishes.
- **models-live-guards**: A live result MUST be applied only if the fetch was not
  cancelled, returned at least one model, the controller still exists and the
  picker is still open; an empty or failed fetch MUST leave the template list.
- **models-fetch-cancelled**: A new refill and a discarded pane MUST each cancel the
  fetch in flight.
- **models-refill-needs-popup**: Refilling with no open picker MUST do nothing.

### Teardown

- **teardown-cancels-and-closes**: When the pane's content is discarded the controller
  MUST cancel the model fetch and close the session.

## Appearance

- **Corner radius**: Not applicable: the source sets none; the chat view and the
  native controls draw their own.
- **Padding**: The chat view is pinned to the container's four edges with no inset;
  an option row is a vertical stack of a label and its control, 4 points apart.
- **Font**: Not set by this controller; the labels are plain system labels and the
  chat view owns its own type.
- **Background**: A themed container using the window-background role, so it follows
  the active theme.
- **Foreground/Text**: Not set here; the status line text comes from the chat view.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: The container starts at 360 by 500 points; the persona field is
  at least 360 points wide and exactly 110 points high.

## States

| State | Appearance change |
|-------|------------------|
| Default (no provider chosen) | Composer disabled; status `Choose an LLM provider in this pane's Settings` |
| Provider chosen, Connect off | Composer enabled; status `Not connected — turn on Connect to Terminal Chat in this pane's Settings` |
| Connect on, no Terminal Chat in the tab | Composer enabled; status `No Terminal Chat in this tab to connect to` |
| Ready (provider, Connect on, Terminal Chat found) | Composer enabled; status cleared |
| Pressed | Not applicable: this controller draws no control of its own; the native controls and chat view own pressed and focused appearance |
| Disabled | Composer disabled only in the no-provider state; the options controls are never disabled |
| Loading | Model picker shows the template list until a live list replaces it; no spinner is shown (a fact of the source) |

## Accessibility

- **Role/trait**: The options use native controls (a checkbox, two pop-up buttons,
  a text field), which carry their own roles; the chat view owns its own.
- **Label requirements**: Each control has a stable accessibility identifier
  (`personaTerminalChat.options.connect`, `.provider`, `.model`, `.persona`); the
  connect checkbox is titled by its text.
- **control-labels**: NEEDS REVIEW: Not implemented in source. The provider picker, model picker and persona field get an accessibility identifier but no accessibility label or label association with the plain text label above each; evidence to settle it is a VoiceOver pass over the options sheet.
- **Announce state changes**: The status line is set through `setStatus` on the chat
  view; the controller posts no accessibility announcement itself.
- **Minimum tap target**: Not applicable: native macOS controls at their standard
  sizes; the source sets no target size.

## Conformance Test Vectors

The only test beside the source is `PersonaTerminalChatToolsTests`
(`testThePersonaChatOffersBrowserToolsAndNamesItsPane`); the other vectors are
derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| persona-001 | tools-composite, tool-caller-is-pane-id (test `testThePersonaChatOffersBrowserToolsAndNamesItsPane`) | Build with browser tools offering `browser_list` and a pane id; list the session's tools; call `browser_list` through the session | Tool names contain `browser_list`; the recorded caller is the pane id's UUID string |
| persona-002 | tools-without-browser, tool-caller-is-pane-id | Build with no browser tools and no pane id | Tool source holds only terminal tools; tool caller is `nil` |
| persona-003 | status-no-provider | Empty state store; load the view | Composer disabled; status `Choose an LLM provider in this pane's Settings` |
| persona-004 | status-not-connected | Store a valid `configurationID`; Connect off | Composer enabled; status begins `Not connected —` |
| persona-005 | status-no-terminal-chat | Valid provider, `connected` = `1`, tab with no Terminal Chat | Status `No Terminal Chat in this tab to connect to` |
| persona-006 | status-clear-when-ready, terminal-chat-lookup | Valid provider, `connected` = `1`, tab with a Terminal Chat | Status cleared; the connected chat is that Terminal Chat's session |
| persona-007 | status-no-provider, configuration-lookup | `configurationID` names a provider deleted from Settings | Treated as no provider (composer disabled) |
| persona-008 | connect-stored-as-flag, options-connect-change | Toggle Connect on, then off | State value `1`, then the key is removed (not `0`); status re-applied each time |
| persona-009 | persona-default, persona-edited | Read persona with nothing stored; commit the default text; commit `  new  `; commit blank | Default; key removed; stored `new`; key removed |
| persona-010 | provider-chosen | Model override `x` set; choose a provider | `configurationID` stored, `model` removed, model list refilled |
| persona-011 | models-keeps-override, models-default-item | Override `m9` not in the template's models | Picker holds `Provider default (<model>)`, the template models and `m9`; `m9` selected |
| persona-012 | models-live-guards | Live fetch returns an empty list | Template list is kept |
| persona-013 | models-fetch-cancelled, teardown-cancels-and-closes | Call `paneContentWillBeDiscarded()` with a fetch in flight | Fetch cancelled; session closed |
| persona-014 | context-values, context-unresolved | Resolve a context with and without a configuration | With: values plus `model`; without: empty model and empty configuration, persona as system prompt |
| persona-015 | options-rows, options-provider-list | Call `makePaneOptionRows()` with two configured providers | Four rows; the provider picker lists `None` and the two names |
| persona-016 | plugin-load-failure-silent | Choose a provider whose plugin identifier does not load | The plugin resolver returns `nil`; status is unchanged; sending a message fails the turn with `No AI provider is configured.` |

## Edge Cases

- **Null and empty input**: No stored keys means no provider, Connect off and the
  default persona (MUST). A blank or default-equal persona removes the key
  (MUST). `None` removes `configurationID` (MUST). A missing base URL is treated
  as an empty string for the live fetch.
- **Boundary values**: The persona field is at least 360 points wide and 110
  points high; the container starts at 360 by 500 (MUST).
- **Stale references**: A stored provider id that no longer exists acts as no
  provider (MUST). A stored model override not in the list is added to the
  list so it stays selectable (MUST), and is cleared when the provider changes
  (MUST).
- **Concurrent access**: The controller is main-actor isolated, and its session
  closures hop to the main actor to read settings. A model fetch runs as a
  background task and applies its result on the main actor only if not
  cancelled; a newer refill cancels the older fetch, so a late result from a
  previous provider is dropped (MUST).
- **Error states**: A live-model fetch that fails or is empty keeps the template list
  (MUST) with no message. A plugin that fails to load yields no plugin and no log; the
  session then fails the turn with `No AI provider is configured.` (`plugin-load-failure-silent`). Edits to the
  persona are never validated.
- **Offline or disconnected state**: With no network the live fetch returns nothing
  and the template list stays (MUST); the chat turn's own failure handling
  belongs to the session. The "disconnected" status refers to the Terminal Chat
  link, which is covered under Status.
- **View not loaded**: Applying the status before `loadView` does nothing (MUST).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `stateStore` | `PaneStateStore` | required | Where the pane's four choices are kept |
| `pluginManager` | `AIPluginManager` | required | Loads provider plugins and resolves templates |
| `browserTools` | `(any ChatToolSource)?` | `nil` | Tools for driving the Browser pane, offered beside the terminal tools |
| `paneID` | `UUID?` | `nil` | Named as the caller of every tool call |
| `connected` (state key) | `1` or absent | absent (off) | Connect to the tab's Terminal Chat |
| `configurationID` (state key) | provider id string | absent | Chosen LLM provider configuration |
| `model` (state key) | string | absent | Model for this pane; absent uses the provider's |
| `persona` (state key) | string | absent (default persona) | The persona's instructions |

## Deep Linking

Not applicable: the pane has no URL of its own; the source has no deep-link
handling.

## Localization

All strings are hardcoded English; none is looked up through a localization
table.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (literal) | Choose an LLM provider in this pane's Settings | Status when no provider |
| none (literal) | Not connected — turn on Connect to Terminal Chat in this pane's Settings | Status when Connect is off |
| none (literal) | No Terminal Chat in this tab to connect to | Status when none found |
| none (literal) | Connect to Terminal Chat | Options toggle title |
| none (literal) | LLM provider / Model / Persona | Option row labels |
| none (literal) | None | First provider item |
| none (literal) | Provider default / Provider default (<model>) | First model item |
| none (literal) | The default persona text | Default system prompt |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the controller starts no animation of its own |
| Increase Contrast | Not applicable here: colors come from the theme and the native controls |
| Differentiate Without Color | Not applicable: states are shown by status text, not color |

## Feature Flags

Not applicable: the source reads no feature flag. The feature is labelled
experimental in a comment, but nothing gates it in this file.

## Analytics

Not applicable: the source records no analytics event.

## Privacy

- **Data collected**: The persona text, the chosen provider id and model, and the
  Connect flag, per pane. Chat messages and tool results are held by the session.
- **Storage**: The four choices in the pane state store, which is an injected `PaneStateStore`: a project window supplies one backed by its `pane_state` rows, and an `EphemeralPaneStateStore` forgets when the pane goes away. Provider API keys are resolved from Settings at turn time and are not
  stored here.
- **Transmission**: Messages and tool results go to the chosen LLM provider; the
  live model list request sends the provider's API key to its base URL. When the
  Terminal Chat is connected to a private terminal, the persona sees only the
  terminal's privacy words (per the source comment; enforced outside this file).
- **Retention**: Choices stay until changed or the pane is removed (or, with an ephemeral store, until the pane goes away); chat history
  belongs to the session.

## Logging

Not applicable: the source makes no log call; a plugin load failure and a fetch
failure are silent (see `plugin-load-failure-silent`).

## Platform Notes

- **SwiftUI**: Replace the view controller with a `View` over an
  `@StateObject` model holding the session; the status is a `Text` or banner
  above the chat view, the options sheet a `Form` with a `Toggle`, two `Picker`s
  and a `TextEditor` (wrap and commit on `.onSubmit`/focus loss with
  `@FocusState`). Pane choices map to `@AppStorage`-style per-pane keys.
- **Compose**: A `ViewModel` exposing a `StateFlow` of status; the options sheet
  a `ModalBottomSheet` with a `Switch`, two `ExposedDropdownMenuBox`es and an
  `OutlinedTextField` with `maxLines`; cancel the live-model call with a
  `Job` tied to the `viewModelScope`; persist choices in DataStore keyed by
  pane id.
- **React/Web**: A component with a reducer for status and a `useEffect` with an
  `AbortController` for the live model fetch; the options a `<dialog>` with a
  checkbox, two `<select>` elements and a `<textarea>` committing on `blur`; give
  each control a `<label htmlFor>` and `aria-describedby` for the status
  (`role="status"`).
- **AppKit / UIKit**: Source file:
  `macOS/Features/TerminalSession/PersonaTerminalChatViewController.swift`, an
  `NSViewController` using `ThemedBackgroundView`, `ChatView`, `AIChatViewModel`,
  `LocalChatSession`, `CompositeChatToolSource`, `TerminalChatToolSource`,
  `PromptedToolCallingPlugin`, `AIProviderResolver`, `OpenAIModelCatalog`,
  `WindowOptionsToggle` and `NSPopUpButton`/`NSTextField` rows, conforming to
  `PaneOptionsProviding` and `PaneContentTeardown`. UIKit would use a
  `UIViewController` with `UIButton` menus (`UIMenu`) in place of
  `NSPopUpButton` and a `UITextView` for the persona.
- **WinUI 3**: A `UserControl` hosting the chat control (an `ItemsRepeater` or
  `ListView` of messages above a multi-line `TextBox`) in a `Grid` with an
  `InfoBar` (`IsOpen`, `Severity=Informational`, `Message`) for the status, driven
  by a view model implementing `INotifyPropertyChanged`; disable the composer
  `TextBox.IsEnabled` in the no-provider state. The options sheet is a
  `ContentDialog` or `Flyout` holding a `ToggleSwitch` (Connect to Terminal
  Chat), two `ComboBox`es (`SelectedValue` bound to the stored id, a first item
  for None and Provider default) and a `TextBox` with `AcceptsReturn="True"`,
  `TextWrapping="Wrap"`, `MinWidth="360"`, `Height="110"`, committing on
  `LostFocus` as well as `Enter`. Set `AutomationProperties.AutomationId` to the
  ids above and `AutomationProperties.Name` on each control, which also closes
  the open question on `control-labels`. Use `HttpClient` with a
  `CancellationTokenSource` for the live model list, and `DispatcherQueue` to
  apply results on the UI thread. Visual states: the composer's `Disabled` state;
  the `InfoBar` supplies the status text.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/TerminalSession/PersonaTerminalChatViewController.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The persona reaches the terminal only through the Terminal Chat in
the same tab.
**Rationale**: The source comment says the chat works the terminal "by way of the
Terminal Chat in the same tab, never the terminal directly", so a private
terminal's privacy words are all the persona sees. The feature is experimental
and deliberately narrow, and "the Terminal Chat" is the first one in the tab.
**Approved**: pending

**Decision**: Every session closure reads the pane's settings when the turn runs.
**Rationale**: The source comment says this applies a changed provider, model or
persona to the next message without rebuilding the session.
**Approved**: pending

**Decision**: Tool definitions are described in the provider's prompt by wrapping the
plugin in `PromptedToolCallingPlugin`.
**Rationale**: The source comment says no provider plugin sends tool definitions
natively and the Claude Code CLI cannot take custom ones.
**Approved**: pending

**Decision**: Choosing a provider clears the model override.
**Rationale**: The source comment says a model belongs to the provider it was
chosen from.
**Approved**: pending

**Decision**: The persona field commits on losing focus, and a blank or
default-equal text removes the stored key.
**Rationale**: The source comment says closing the sheet without pressing Return
must not throw the edit away; storing nothing for the default keeps the default
text updatable in one place.
**Approved**: pending

**Decision**: The status is re-applied on appear.
**Rationale**: The source comment says the Terminal Chat can only be found once
the pane is in the tree.
**Approved**: pending

**Decision**: Live model lists replace the template list only when non-empty and
current.
**Rationale**: Inferred from the guards (not cancelled, not empty, picker alive):
a slow or failed fetch must not blank a usable list or fill a closed sheet.
**Approved**: pending

**Decision**: Connect is stored as `1` and removed when off.
**Rationale**: Inferred from the setter; it keeps the default (off) as an absent
key like the other three settings.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

The session, plugin loading, provider resolution and chat drawing sit in other
types, but this one controller also holds the settings storage, the status
rules, the model-list fetch and the options-sheet construction, so
separation-of-concerns is partial. `PersonaTerminalChatToolsTests` covers the
tool wiring and the tool caller only; no test covers the status rules, the
settings round trips, the model list or teardown, so coverage is partial. A
failed live fetch falls back to the template list, but a plugin that fails to
load is logged nowhere and surfaces only as the session's generic
`No AI provider is configured.` turn failure (`plugin-load-failure-silent`),
so error handling is partial. The controls carry accessibility identifiers but
not labels (the open question on `control-labels`), so screen-reader support is
partial. Every user-facing string is an English literal, so no-hardcoded-strings
fails.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
