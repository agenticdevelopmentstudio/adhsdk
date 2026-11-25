
The registry produces user-facing error text in English only, with no localization mechanism:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal) | `A model entry needs a name` | `ModelRegistryError.invalidEntry`, name blank |
| (none; literal) | `A model entry needs a plugin identifier` | `invalidEntry`, plugin identifier empty |
| (none; literal) | `A model entry needs a template id` | `invalidEntry`, template id empty |
| (none; literal) | `No model entry with id <uuid>` | `ModelRegistryError.notFound` |
| (none; literal) | `AI plugin not installed: <plugin>` | `ModelRegistryError.pluginNotInstalled` |
| (none; literal) | `AI plugin <plugin> has no template '<template>'` | `ModelRegistryError.unknownTemplate` |
| (none; literal) | `Could not store the secret '<field>' in the Keychain` | `ModelSecretStoreError.writeFailed` |
| (none; literal) | `Could not remove the secret '<field>' from the Keychain` | `ModelSecretStoreError.removeFailed` |
| (none; literal) | `Empty reply from the model` | `ModelTestResult.message` on an empty reply |
| (none; literal) | `Reply with the single word OK.` | The test prompt sent to the model (not shown to the user) |

