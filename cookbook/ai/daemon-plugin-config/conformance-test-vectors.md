
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| daemon-plugin-config-001 | field-key-format, plain-ids-stay-readable | `fieldKey(plugin: "acme", field: "apiKey")` | `aiplugin.acme.field.apiKey` (`DaemonPluginConfigTests.testFieldKeyShapeIsStable`) |
| daemon-plugin-config-002 | dot-escaped, component-encoding | `fieldKey(plugin: "com.example.plugin", field: "apiKey")` | `aiplugin.com%2Eexample%2Eplugin.field.apiKey` (`DaemonPluginConfigTests.testReverseDNSIdentifierEncodesItsDots`) |
| daemon-plugin-config-003 | distinct-pairs-distinct-keys | `fieldKey(plugin: "plugin.a", field: "apiKey")` versus `fieldKey(plugin: "plugin.b", field: "apiKey")` | The two keys differ (`DaemonPluginConfigTests.testDistinctPluginsWithSameFieldGetDistinctKeys`) |
| daemon-plugin-config-004 | distinct-pairs-distinct-keys | `fieldKey(plugin: "x.field.y", field: "z")` versus `fieldKey(plugin: "x", field: "y.field.z")` | The two keys differ (`DaemonPluginConfigTests.testDelimiterCollisionIsPrevented`) |
| daemon-plugin-config-005 | secret-fields-key-format, ledger-never-collides-with-field | `secretFieldsKey(plugin: "acme")` versus `fieldKey(plugin: "acme", field: "secretfields")` | Ledger is `aiplugin.acme.secretfields`; it differs from the field key (`DaemonPluginConfigTests.testSecretFieldsLedgerKeyNeverCollidesWithAFieldKey`) |
| daemon-plugin-config-006 | deterministic | Call `fieldKey(plugin: "p", field: "f")` and `secretFieldsKey(plugin: "p")` twice each | Equal results per pair (`DaemonPluginConfigTests.testKeysAreDeterministic`) |
| daemon-plugin-config-007 | selected-plugin-key | Read `selectedPluginKey` | `ai_plugin_id` |
| daemon-plugin-config-008 | component-encoding | `fieldKey(plugin: "a%b", field: "c d")` | `aiplugin.a%25b.field.c%20d` |
| daemon-plugin-config-009 | component-encoding | `fieldKey(plugin: "", field: "")` | `aiplugin..field.` (an empty component stays empty) |

