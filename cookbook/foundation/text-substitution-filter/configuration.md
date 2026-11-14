
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `matchingCase` | `Bool` | `false` | Write each replacement in the case of the text it replaces (`casing(_:like:)`). |
| `wholeWords` | `Bool` | `false` | `revealing` only: replace an alias only where no letter or digit touches either end. |

The options above are per-call arguments (`matchingCase` on both directions, `wholeWords` on `revealing`); the pairs and the text form are initialiser inputs, described in the Overview.

The component reads no environment variable and no settings key.

