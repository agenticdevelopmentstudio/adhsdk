
The provider model picker is the one control for choosing an AI provider
configuration and its model together. It is two settings rows: a provider
popup, and below it the model picker control
([adhsdk.ingredient.ai.plugins.model-picker](cookbook:b3059939-21f5-414b-82e4-edd11b192ae8)) that opens the popover
model chooser. Every settings panel that picks a provider and a model uses
it, rather than building its own popup and model field.

It works over a provider source, an interface with two implementations:

- **Local**: the app's plugin manager and its stored provider configurations
  ([adhsdk.ingredient.ai.plugins.plugin-runtime](cookbook:e886e448-6aa5-4359-979d-49fba713ab2a)).
- **Daemon**: the provider configurations the session daemon reports,
  resolving each one's template through an optional plugin manager so the
  model list and the default model's name can be shown; the default model
  comes from this app's own per-configuration model setting, since the
  daemon's list carries no model. In a host without a plugin manager no
  default is known, the model row shows the stored model, and its chooser
  lists only that model, but still opens.

The caller supplies the settings it binds to: the provider selection and a
function from a provider id to that provider's model setting (one shared
setting several features share, or one per configuration).

Everywhere a model is stored, an empty string means the provider's default
model. A provider configuration's default model is set in the AI Providers
panel and is what the daemon receives as that configuration's model, so a
feature that stores an empty model follows it.

