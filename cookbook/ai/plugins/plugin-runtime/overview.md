
This runtime layer turns a discovered plugin bundle into something a chat UI
can talk to. It has three responsibilities: (1) a plugins coordinator owns
the plugin manager for the app's lifetime and runs discovery, one-time legacy
migration, and first-run seeding, in that order, at construction; (2) a
family of configuration types (a provider configuration, its per-configuration
store, a resolver, first-run defaults, a one-time migration, and a legacy
per-plugin config store) model a user's named provider configurations,
persist their field values (secrets routed to secure storage), and resolve a
configuration back into the plugin identifier, model, and value bag a request
needs; and (3) two parallel configuration-provider-plus-chat-engine pairs
drive an actual conversation through a plugin — a deprecated chat-backend path
(a chat-backend adapter, a provider chat session, a plugin-backed
configuration provider, and a single-configuration provider) riding a
chat-backend session wrapper, and a current chat-session path (a tool-calling
chat session and an MCP tool source) that also runs a bounded tool-calling
loop. Every type in this component is confined to a single execution context,
is declared safe for concurrent use through its own explicit synchronization,
or is a plain immutable value safe to share — never left unspecified.

The AI Providers settings panel, where a person edits these configurations,
is described here too: each configuration's editor sets the configuration's
default model through the model picker control
([adhsdk.ingredient.ai.plugins.model-picker](cookbook:b3059939-21f5-414b-82e4-edd11b192ae8)), and its secret fields
use the secure text row with reveal
([adhsdk.ingredient.ui.settings.rows.secure-text-edit-view](cookbook:2e0bf51e-905d-476d-9c0c-48465174ba59)).
Every other place that chooses a provider and a model uses the combined
provider model picker
([adhsdk.ingredient.ai.plugins.provider-model-picker](cookbook:c9385bf6-3abc-486b-82b5-d57a62d86735)), and an empty
stored model there means this configuration's default model.

