
- **Null / empty input**: A sync with empty `configs` and nil `removedConfigIds` is a full sync that deletes every stored configuration. With an empty non-nil `removedConfigIds` it deletes nothing. An empty `values` or `secrets` map is valid.
- **Boundary values**: Not applicable: the contract holds no numeric limits; its size is the number of configurations.
- **Concurrent access**: Not applicable to the types, which are `Sendable` values. The daemon serialises the apply: its `applyAIProviderSync` takes a lock so HTTP and XPC callers cannot interleave; that behavior is specified by the daemon, not by this contract.
- **Error states**: A payload missing `enabled` or `configs` fails to decode, and a malformed UUID in `id`, `selectedConfigId` or `removedConfigIds` fails to decode, each throwing a `DecodingError`. The types validate no field contents: an empty `name` or unknown `templateId` is accepted.
- **Offline / disconnected state**: Not applicable: the types do no networking. Each push sends one body; delivery, retries and acknowledgement belong to the sender, and the ledger records only a push that landed.
- **Older host**: A host that predates `removedConfigIds` omits the key, and the daemon then treats the sync as the complete registry. A partial-sync host must therefore always send the key (see **partial-sync-sends-key**), or it risks deleting another host's configurations.

