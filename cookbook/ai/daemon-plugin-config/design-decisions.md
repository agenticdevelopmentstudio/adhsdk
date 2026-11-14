
**Decision**: Each dynamic key component is percent-encoded with only alphanumerics left raw.
**Rationale**: Plugin identifiers are reverse-DNS and contain dots, which are also the key's structural delimiter. Escaping the dot and the percent sign makes the join injective, so two different (plugin, field) pairs can never share a key and one plugin's credential cannot overwrite or leak into another's. The test file states this purpose.
**Approved**: pending

**Decision**: The key strings are an internal daemon detail, not a cross-process contract.
**Rationale**: The doc comment says the wire protocol is the `fields` and `secrets` maps keyed by descriptor field key; the keys here "need only agree with themselves". A port may therefore choose different key strings provided its own reads and writes agree, but it MUST keep the collision-freedom property.
**Approved**: pending

**Decision**: A separate ledger key records which secret fields are stored for a plugin.
**Rationale**: The daemon cannot enumerate its own secret namespace, so on a plugin switch it reads the ledger to know which Keychain entries to clear. The ledger key lacks the `field` segment so it can never equal a field key, even for a field named `secretfields`.
**Approved**: pending

**Decision**: An empty `selectedPluginKey` value selects the zero-config claude_cli path.
**Rationale**: The doc comment defines empty or absent as the default path, so no plugin has to be configured for completion to work.
**Approved**: pending

