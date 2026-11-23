
- An empty persona list renders the root level's empty message, `"No personas yet."`, rather than
  an empty items array with no explanation.
- A facet id present in the facet rail but outside the currently supported set (8 of the 13
  declared facets) MUST resolve to the fixed unavailable-facet notice, never to a broken or
  partially-rendered form.
- A path whose facet id matches nothing in the declared facet set (not merely an unsupported id,
  but an unknown one) MUST resolve to an empty result the same way an unknown persona id does.
- Every blank optional text field on a facet save (`description`, `character`, `voice`,
  `examples`) is mapped to absent through the blank-to-nothing helper, never persisted as `""`.
- Selecting the `"llm"` facet's `model` for a service that does not actually offer that model id
  (stale selection, or the service was switched) MUST clear `model` to absent on save rather than
  persist a mismatched pair.
- A model that is switched off and no longer offered by the provider stays in the service's
  `models` (`available: false`, `offered: false`) so the workspace can switch it back on; the
  editor's select MUST NOT list it, but MUST still show it as the current value when a persona
  saved it.
- A wire model item that omits `available` or `offered` MUST be read as `true` for each, so an
  older backend that never sends them makes every model available.
- A model that is a bare string on the wire is read as `{ id }`, which then takes the same
  defaults (`available` and `offered` both `true`).
- A service whose models are all switched off leaves the editor's model select with no choice
  beyond "No model selected" (and the saved model, if any, labelled "(not available)").
- Any failure from the underlying data source (e.g. offline) on the root-level listing,
  child-content resolution, create, save, or delete MUST propagate as a wrapped domain error,
  never be swallowed.
- The demo-eligibility check treats a raw config that is not an object at all (`"not even an
  object"`) the same as one that is well-formed but switched off: `false`, with no thrown error.
- Listing interest documents on a corpus with more than 500 documents silently returns only the
  first (oldest-id-first) 500; the caller receives no signal that more documents exist.
- The demo-preview operation called with a `history` longer than the maximum preview-history
  length is rejected by the server with a 400; this client sends the caller's history as given and
  applies no truncation of its own.
- Updating a special interest given a patch that includes `personaId` or `bucketId` silently drops
  both from the outgoing request rather than sending (and having the server reject) them.

