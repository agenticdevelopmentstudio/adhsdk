
No given source externalizes strings. These hardcoded English strings are facts about the implementation, not gaps:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (inline) | `YOUR_TOKEN` | Token placeholder in every generated snippet |
| (inline) | `api-explorer: endpoint slug collision on "<slug>" (<key> vs <key>)` | Developer-facing error thrown by the slug index |
| (inline) | `string`, `any`, `never`, `object`, `other` | Type labels and the untagged-tag bucket |

Error text for a failed list comes from `errorMessage` in `@adh-sdk/ui`, and the `Request failed` fallback belongs to the endpoint detail view; neither is produced here.

