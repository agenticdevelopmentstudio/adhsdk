
**Decision**: The sync carries the whole set of configurations rather than a single plugin-keyed slot.
**Rationale**: Two hosts share one daemon registry, so state must be keyed by configuration identity rather than by plugin; a plugin-keyed slot would let one host's push overwrite the other's configuration of the same plugin.
**Approved**: pending

**Decision**: `removedConfigIds` distinguishes a partial sync (non-nil) from a full one (nil).
**Rationale**: Two hosts share one daemon registry, so a host must be able to delete exactly what it dropped; nil keeps older hosts working as full-set mirrors.
**Approved**: pending

**Decision**: `enabled` and `selectedConfigId` stay on the wire though the daemon ignores them.
**Rationale**: Summaries state has a single writer, `POST /preferences/summaries`, so these fields carry no meaning; older hosts still send them, and removing the keys would break their decoding.
**Approved**: pending

**Decision**: Secrets travel in the same body as values, in a separate `secrets` map where an empty value clears the credential.
**Rationale**: The daemon stores values in its settings table and secrets in the keychain, so the wire must separate them; an empty value is the only clear signal the contract has.
**Approved**: pending

**Decision**: The contract lives in Core with aliases in the plugin layer.
**Rationale**: An HTTP client must be able to send the contract without importing the plugin layer, and the aliases keep existing `import AIPluginKit` call sites compiling.
**Approved**: pending

