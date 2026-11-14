
**Decision**: The sync carries the whole set of configurations rather than a single plugin-keyed slot.
**Rationale**: The source comment states the daemon mirrors the full registry keyed by configuration identity.
**Approved**: pending

**Decision**: `removedConfigIds` distinguishes a partial sync (non-nil) from a full one (nil).
**Rationale**: Two hosts share one daemon registry, so a host must be able to delete exactly what it dropped; nil keeps older hosts working as full-set mirrors.
**Approved**: pending

**Decision**: `enabled` and `selectedConfigId` stay on the wire though the daemon ignores them.
**Rationale**: The source comments say they are kept for wire compatibility only; summaries state has a single writer, `POST /preferences/summaries`.
**Approved**: pending

**Decision**: Secrets travel in the same body as values, in a separate `secrets` map where an empty value clears the credential.
**Rationale**: The source describes the split so the daemon can store each part in its proper place, and an empty value is the only clear signal the contract has.
**Approved**: pending

**Decision**: The contract lives in Core with aliases in the plugin layer.
**Rationale**: The aliases file states it moved down so an HTTP client can send it without importing the plugin layer, and the aliases keep existing call sites compiling.
**Approved**: pending

