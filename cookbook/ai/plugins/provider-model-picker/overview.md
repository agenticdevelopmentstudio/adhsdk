
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

