
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `document` | the dirty, saving, gone, changedElsewhere, conflict, saveError, save, overwrite, revert and takeTheirs members of a versioned document | required | The document, from `useVersionedDocument` |
| `noun` | string | `"document"` | What the document is called in default notices |
| `messages` | `{ gone?, changedElsewhere?, conflict? }` | `{}` | Replaces any notice's wording |
| `className` | string | none | Applied to the wrapper element |

