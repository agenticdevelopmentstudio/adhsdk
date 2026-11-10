
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `categoryDeleteDialog.title.delete` | `Delete "{categoryName}"?` | Dialog title; category name inserted via template string |
| `categoryDeleteDialog.label.main` | `This deletes the category only. Any {itemNoun} filed under it are not deleted — they become uncategorized.` | Main explanation; `itemNoun` is dynamic per host |
| `categoryDeleteDialog.label.orphaned.singular` | `This subcategory is filed nowhere else, so it is deleted too:` | Message when exactly one subcategory is orphaned |
| `categoryDeleteDialog.label.orphaned.plural` | `These subcategories are filed nowhere else, so they are deleted too:` | Message when more than one subcategory is orphaned |
| `categoryDeleteDialog.label.orphaned.items` | `Their {itemNoun} become uncategorized as well.` | Trailing sentence for the orphaned section, required by **shows-orphaned-items-note**; `itemNoun` is dynamic |
| `categoryDeleteDialog.button.delete` | `Delete` | Primary action button label |
| `categoryDeleteDialog.button.cancel` | `Cancel` | Dismissal button label |

Keys are namespaced under `categoryDeleteDialog.*` so they cannot collide with another dialog's `title.delete`/`button.delete`/`button.cancel` keys.

