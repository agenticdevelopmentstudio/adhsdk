
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
