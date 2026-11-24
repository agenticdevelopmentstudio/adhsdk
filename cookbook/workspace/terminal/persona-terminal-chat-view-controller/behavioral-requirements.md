
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

