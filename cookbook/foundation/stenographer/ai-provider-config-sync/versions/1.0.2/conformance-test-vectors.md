
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ai-provider-config-sync-001 | round-trip, sync-fields, config-fields | A sync with `enabled` true, a `selectedConfigId`, and one configuration with a `baseURL` value and an `apiKey` secret; encode then decode. | The decoded value equals the original (test: testRoundTrip). |
| ai-provider-config-sync-002 | sync-decode-tolerance | Decode `{"enabled":false,"configs":[]}`. | `selectedConfigId` is nil, `enabled` is false, `configs` is empty (test: testDecodesMissingSelectionAsNil). |
| ai-provider-config-sync-003 | nil-removed-full-sync, sync-decode-tolerance | Decode `{"enabled": true, "configs": []}`. | `removedConfigIds` is nil (test: testSyncDecodesWithoutRemovedConfigIds). |
| ai-provider-config-sync-004 | sync-initializer | Build a sync without passing `removedConfigIds`. | `removedConfigIds` is nil (derived from the source default; no test). |
| ai-provider-config-sync-005 | empty-removed-is-partial, partial-sync-sends-key | Build a sync with `removedConfigIds` of an empty array and encode it. | The encoded key is present as an empty array, which the daemon reads as a partial sync (test: PreferencesServiceTests, testPartialSyncUpsertsAndLeavesOtherHostsConfigurationsAlone). |
| ai-provider-config-sync-006 | non-nil-removed-partial-sync | A sync with `removedConfigIds` of one id and one config. | The daemon upserts the config, deletes that one id and leaves other stored configurations (test: PreferencesServiceTests, testPartialSyncDeletesExactlyTheListedIdsAndTheirSecrets). |
| ai-provider-config-sync-007 | nil-removed-full-sync | A sync with nil `removedConfigIds` listing one config. | The daemon deletes every stored configuration not in `configs` (test: PreferencesServiceTests, testRemovingAConfigDeletesItsSecret). |
| ai-provider-config-sync-008 | sync-decode-required | Decode `{"configs":[]}`. | Decoding throws `keyNotFound` for `enabled` (derived from the synthesized conformance; no test). |
| ai-provider-config-sync-009 | empty-secret-clears | A configuration with `secrets` of `apiKey` set to the empty string. | The wire value is the empty string, which the daemon reads as clearing the credential (source: the doc comment and the daemon's clean-replace secret storage; no test). |
| ai-provider-config-sync-010 | aliases | `AIPluginKit` consumers use `AIProviderConfigSync`. | The name resolves to the Core type; the round-trip test in `AIPluginKitTests` compiles against the alias (test: testRoundTrip). |
| ai-provider-config-sync-011 | config-initializer | Build `ResolvedProviderConfig` with no `values` or `secrets` arguments. | Does not compile; both are required (derived from the source; compile-time). |

