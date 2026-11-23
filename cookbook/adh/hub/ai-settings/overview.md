
AI Settings is the screen where a workspace connects AI providers and chooses which of their models
it can use. It is the web package `@adh-sdk/ai-settings`. Its main export, `ServicesSection`, is a
two-part surface: a rail that lists the workspace's service connections (each labelled with its name
and subtitled with its provider kind), and a pane that edits the open one. A service is created in a
modal over the rail, never in a blank editor. The editor holds the service's fields (name, provider,
base URL, API key), a Connection group with a Connect button, and a Models group with a Refresh
button and a table of the provider's models.

The package was carved out of the personas package and keeps that package's behavior, with the phase 8
changes stated below as requirements. After phase 8 each model in the table has an Available checkbox,
ticked by default, which switches the model on or off for this workspace, and a model the provider no
longer lists but which is still switched off shows as "No longer offered". `AiSettingsSection` is
`ServicesSection` titled "AI Settings". The service list is read through `useUserServices`, one cache
entry shared with the persona editor's service picker; its key keeps the name
`PERSONA_SERVICES_CACHE_KEY` and the value `"persona-services"`. The data client, the model and service
types, and the wire shapes belong to the personas data module (see
[adhsdk.ingredient.adh.hub.personas](cookbook:4af83bb1-0178-462a-b0fc-ae009b63133f)); this recipe covers
the screen, its hook and its package layout.

