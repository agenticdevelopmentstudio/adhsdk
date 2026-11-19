
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
