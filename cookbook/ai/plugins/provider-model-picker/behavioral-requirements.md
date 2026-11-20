
### Provider Source

- **source-interface**: A provider source MUST list the selectable provider
  configurations (id and display name, in the source's order), MUST say
  whether that list is authoritative (complete), MUST tell the control when
  the list changes, and for a given configuration id MUST return its default
  model id and a chooser context (which also supplies model display names),
  each of which MAY be none.
- **local-source**: The local source MUST list the app's stored provider
  configurations, resolve each through the plugin manager, report a
  configuration's default model as its per-configuration model setting's
  resolved value (the stored model, else the template's default), and build
  the chooser context from the resolved plugin, template and the
  configuration's base URL and key.
- **daemon-source**: The daemon source MUST list the configurations the
  daemon reports (ids, names, plugins and templates; the daemon's reply
  carries no model). With a plugin manager that resolves a configuration's
  template, it MUST report that configuration's default model the way the
  local source does, from this app's own per-configuration model setting
  for that id (the stored model, else the template's default), and build the
  chooser context, which supplies display names, from that template. With
  no plugin manager, or when the template does not resolve, it MUST report
  no default model and return a chooser context over a bare template that
  lists only the current model (none when it is empty).
- **daemon-source-async**: The daemon source MUST load the daemon's list off
  the UI thread and MUST tell the control when it has loaded, so the control
  rebuilds its popup and its model row, both when the list changes and when
  the source first becomes authoritative with an unchanged list; until then
  the popup lists only the leading choices, and the source is not
  authoritative.
- **daemon-not-running**: A failed or unanswered list request MUST leave the
  daemon source's list as it was and the source not authoritative, with no
  error shown; the control stays as in Loading, and the request is retried
  each time the popup is about to open.

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
- **stale-selection-kept**: The control MUST NOT write the provider
  selection setting except for the person's own choice in the popup. A stored
  selection that no entry matches is kept: while the source is not
  authoritative (a daemon that has not answered) the popup shows its first
  entry, and once the source is authoritative the popup gains a last entry,
  "Unavailable Provider", carrying the stored value, and selects it. With no
  entries at all, nothing is selected or written.
- **provider-change-resets-model**: When the model setting is shared (the
  caller returns the same setting for every provider), choosing a different
  provider MUST set it to `""` when it is not already empty, so the model
  becomes the new provider's default; for a leading choice only the setting
  the caller returns for no provider is cleared, if it returns one. The model
  write MUST land before the selection write, so an observer of the selection
  reads the cleared model. A per-provider model setting MUST NOT be cleared,
  since it already belongs to that provider. Re-choosing the provider already
  selected MUST NOT write either setting.
- **sentinel-disables-model**: With a leading choice selected, the model row
  MUST be disabled and read "Choose a Model".
- **model-display-rule**: The model row MUST show, in order of preference,
  the display name of the stored model when it is non-empty, else the display
  name of the provider configuration's default model, else "Choose a Model".
- **model-choice-binding**: A model chosen in the popover MUST be written to
  the selected provider's model setting, as `""` when it is that provider's
  default model, so the setting keeps following the default.
- **external-change-refresh**: A change to the provider selection setting or
  to the selected provider's model setting made outside the control MUST
  update the popup and the model row.
- **chooser-opens-without-catalog**: With the daemon source and no plugin
  manager, the model row MUST stay enabled for a configuration (not a
  leading choice) and its chooser MUST open, listing nothing but the stored
  model. With the local source and no plugin manager, the source returns no
  chooser context, so the model row is disabled.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

