
**Decision**: The wire types live in the Core framework and the plugin layer re-exposes them by alias, rather than moving every call site.
**Rationale**: The source comment states the reason: an HTTP client must be able to send the contract without importing the plugin layer, and aliases keep existing `import AIPluginKit` call sites compiling. The cost is one extra name for each type.
**Approved**: pending

**Decision**: The related synchronization recipe's references still name an older plugin-layer path for the structs; the structs now live under the Core framework's `Stenographer` folder, and the Core struct also has an optional `removedConfigIds` field that recipe does not list.
**Rationale**: Recorded as an observed divergence from the sibling recipe, not corrected here, because this recipe covers only the aliases and the sibling recipe is owned separately.
**Approved**: pending

