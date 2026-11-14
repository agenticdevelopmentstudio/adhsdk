
- **namespace-only**: The component MUST be a stateless namespace (a caseless enum) with only static members and no state.
- **selected-plugin-key**: `selectedPluginKey` MUST equal the literal `ai_plugin_id`. It names the settings-table key that holds the identifier of the plugin to complete with.
- **selected-plugin-empty-means-claude-cli**: An empty or absent value at `selectedPluginKey` MUST mean "use the zero-config claude_cli path", per the key's doc comment. The component only documents this meaning; the reader of the key applies it. In the current source the key is read and then reset to empty only by the daemon's one-time legacy cleanup in `PreferencesService`.
- **field-key-format**: `fieldKey(plugin:field:)` MUST return `aiplugin.<encoded plugin>.field.<encoded field>`.
- **secret-fields-key-format**: `secretFieldsKey(plugin:)` MUST return `aiplugin.<encoded plugin>.secretfields`.
- **component-encoding**: Each dynamic component (plugin identifier, field key) MUST be percent-encoded with only ASCII-and-Unicode alphanumerics left unescaped, so every other character, including `.` and `%`, is escaped.
- **dot-escaped**: A `.` in a component MUST appear as `%2E`, so it cannot be read as a structural delimiter.
- **plain-ids-stay-readable**: A component made only of alphanumeric characters MUST pass through unchanged.
- **distinct-pairs-distinct-keys**: Two distinct (plugin, field) pairs MUST map to distinct field keys. This is the collision-freedom guarantee in the doc comment, and it holds because the encoding escapes both `.` and `%`.
- **ledger-never-collides-with-field**: The secret-fields ledger key for a plugin MUST differ from the field key of any field of that plugin, including a field named `secretfields`, because the field key always carries the extra `field` segment.
- **deterministic**: The same inputs MUST return the same key on every call, with no salting or ordering dependence, so a value written in one request is found in the next.
- **ledger-purpose**: The ledger key MUST be the place the daemon records the newline-joined descriptor field keys whose secrets it holds for a plugin. The doc comment says the daemon records it on write so it can clear exactly those Keychain entries on a plugin switch, because it cannot enumerate its own secret namespace. In the current source the only caller that reads it is the daemon's legacy cleanup in `PreferencesService` (`clearStoredSecrets(forPlugin:)`, run from `cleanUpLegacyIfNeeded`); the registry that stores configurations today keys its values and ledgers through `AIProviderConfigKeys` instead.
- **no-io**: The component MUST NOT read or write the settings table, the Keychain or any file; storage belongs to the caller.
- **encoding-fallback**: When percent-encoding returns nil, the component MUST fall back to the raw, unencoded text for that component.
- **thread-safety**: Every member MUST be safe to call concurrently, since all are pure functions of their arguments.

