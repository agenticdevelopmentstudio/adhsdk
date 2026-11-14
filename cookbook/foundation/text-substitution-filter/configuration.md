
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `pairs` | `[Pair]` | none | The ordered alias and real-text pairs; pairs with an empty side are dropped at initialisation. |
| `parsing` | `String` | none | Text form: `alias = real` entries separated by `;` or newlines. |
| `matchingCase` | `Bool` | `false` | Write each replacement in the case of the text it replaces (`casing(_:like:)`). |
| `wholeWords` | `Bool` | `false` | `revealing` only: replace an alias only where no letter or digit touches either end. |

The component reads no environment variable and no settings key.

