
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

