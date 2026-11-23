
AI Settings is the screen where a workspace connects AI providers and chooses which of their models
it can use. It is the web package `@adh-sdk/ai-settings`. Its main export, `ServicesSection`, is a
two-part surface: a rail that lists the workspace's service connections (each labelled with its name
and subtitled with its provider kind), and a pane that edits the open one. A service is created in a
modal over the rail, never in a blank editor. The editor holds the service's fields (name, provider,
base URL, API key), a Connection group with a Connect button, and a Models group with a Refresh
button and a table of the provider's models.

Each model in the table has an Available checkbox, ticked by default, which switches the model on or
off for this workspace, and a model the provider no longer lists but which is still switched off shows
as "No longer offered". `AiSettingsSection` is `ServicesSection` titled "AI Settings". The service list
is read through `useUserServices`, one cache entry shared with the persona editor's service picker; its
key keeps the name `PERSONA_SERVICES_CACHE_KEY` and the value `"persona-services"`. The data client, the
model and service types, and the wire shapes belong to the personas data module; the personas package's
re-exports of this package, its import of it in `PersonasSection` and the persona editor's model select
are specified by [adhsdk.ingredient.adh.hub.personas](cookbook:4af83bb1-0178-462a-b0fc-ae009b63133f),
and the `ai-settings` hub segment and the redirect-only `llm-providers` and `persona-services` segments
by [adhsdk.ingredient.adh.sites.site-registry](cookbook:9069ccf9-0357-4311-9671-91ee2793adae). This
ingredient covers the screen, its hook and its package layout.

The package was carved out of the personas package in phase 8 and keeps that package's behavior; the
Available column and "No longer offered" were added in the same phase.

