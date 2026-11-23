
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ecosystemId` | string | none, required | The product's ecosystem uuid every pane reads for. |
| `caller` | `"manager"` or `"product_admin"` | `manager` | Which seat is using the roles, sign-up list and sets panes; see the ecosystem configuration recipe. |
| `hideAdminRecords` | boolean | false | On the requests, pending and invites panes, hides the notes, history and Admin notes action. |
| `{ enabled, hasSite }` | object | none | The input to `visibleProductTopics`: the `product_admin_site` switch and whether a site exists. |

