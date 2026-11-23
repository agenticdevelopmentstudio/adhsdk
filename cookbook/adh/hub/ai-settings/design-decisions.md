
**Decision**: `PERSONA_SERVICES_CACHE_KEY` keeps its name and its value `"persona-services"` after the
move to this package.
**Rationale**: The design's SDK section states the admin config-set services hook shares the cache
entry through that key; renaming the value would split the cache, and renaming the constant would
break every importer while the personas re-export is in place.
**Approved**: pending

**Decision**: The models a screen shows come from the service row, not from a live model route.
**Rationale**: Per the design, the models table and the persona editor both read the service row's
cached models, so availability is annotated once where the row is built and every screen agrees.
**Approved**: pending

**Decision**: A model switched off that the provider no longer lists is kept in the list as "No longer
offered", unticked.
**Rationale**: Per the design, off records are free text keyed by model name and survive a refresh; the
row stays visible so the record can be cleared.
**Approved**: pending

**Decision**: `ServicesSection`, `useUserServices` and the `fmtDate` helper (`format.ts`) were moved
from the personas package into this one with `git mv`, not copied, so file history follows them.
**Rationale**: Per the design, the move is one carve-out in phase 8; the personas package's re-exports,
which keep host imports working until Cleanup removes them, are specified by
[adhsdk.ingredient.adh.hub.personas](cookbook:4af83bb1-0178-462a-b0fc-ae009b63133f).
**Approved**: pending

**Decision**: The `title` default stays "Persona Services" on `ServicesSection`; `AiSettingsSection`
supplies "AI Settings".
**Rationale**: Existing embedded callers are unchanged, as the source comment on the prop states
("Defaults to the feature's own name so standalone/embedded callers are unchanged").
**Approved**: pending

**Decision**: Creating a service is a modal, never a blank editor leaf.
**Rationale**: The source comment cites the `must-create-in-modal` rule of
[adhsdk.recipe.ui.blocks.hierarchical-topic-detail](cookbook:0bba1f5b-bc8d-4f76-b1c9-329b627f7ee8); the
created service is then selected so its Connection and Models groups open.
**Approved**: pending

**Decision**: A failed template read is reported and answered with an empty catalog.
**Rationale**: Per the source comment, the picker is an accelerator, and losing it must not stop anyone
typing a service in by hand.
**Approved**: pending

**Decision**: Edit mode does not re-prompt for URL or header variables.
**Rationale**: The source comment on the draft seed explains the variables cannot be recovered from a
concrete URL, and that object-valued draft fields would read as permanently dirty under the dirty-draft
hook's identity comparison; encode them as primitives if prompting is ever re-enabled.
**Approved**: pending

**Decision**: Save is gated on dirty and valid, and the editor publishes an exit guard only while dirty.
**Rationale**: Per source comments, a grey Save with no reason, and a draft discarded silently on every
exit that skips Save, were defects; registering only on dirt stops browsing from prompting.
**Approved**: pending

**Decision**: The list read reports and rethrows, with the resource's own reporting off.
**Rationale**: Per the source comment, the list is the surface and shows the failure, and one failure
must not be reported twice under two contexts.
**Approved**: pending

