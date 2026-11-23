
The Personas domain has two given implementations of one contract. On Apple, a navigation data
source drives a list-of-personas root level, a fixed 13-item facet rail per persona, and one form
per facet, backed by a persona data source contract the app repo implements over its own API
client. On the web, a family of hand-written clients covers a much larger surface: persona CRUD
and services, the demo-chat eligibility predicate and preview endpoint, the chat-status
word/glyph resolver, owner-level tool/may-act/approval grants, per-user tool consent, and the
special-interests research-corpus clients. Both sides agree that a persona is edited
facet-by-facet but sent as one whole payload on every update, and that everything past the core
CRUD + services surface — abilities, may-act, chat status, demo chat, special interests — is
either not yet wired into the Apple facet rail (only 5 of the 13 declared facets are currently
supported) or has no Apple client at all in the given sources.

Phase 8 (AI Settings) adds a per-workspace on/off switch for each model of a provider
connection. The data client gains `services.setModelAvailability` and each model it returns
carries `available` and `offered`; the Apple model item gains an optional `available`; and the
web personas feature package stops owning the provider UI (it moves to the `@adh-sdk/ai-settings`
feature package, specified by
[adhsdk.ingredient.adh.hub.ai-settings](cookbook:5fdf4ce9-cb7e-4490-a6d6-066690ef07ca)), keeps
re-exporting it for one phase, and filters its model select by availability.

