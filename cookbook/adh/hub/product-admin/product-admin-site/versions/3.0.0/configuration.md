
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ecosystemId` | string | none, required | The product's ecosystem uuid every pane reads for. |
| `caller` | `"manager"` or `"product_admin"` | `manager` | Which seat is using the roles, sign-up list and sets panes; see the ecosystem configuration recipe. |
| `hideAdminRecords` | boolean | false | On the requests, pending and invites panes, hides the notes, history and Admin notes action. |
| `{ consoleLive }` (`ProductSiteRailState`) | object or undefined | none | The input to `visibleProductTopics` and `runAtProductSite`: whether the product's `/admin` console is live (on and answering at the product's address); undefined while the site is not known. |
| `ecosystemId`, `productName`, `help` | string, string, node | `ecosystemId` required | `ProductSitePane`'s inputs: the product, its name for the pane's sentences, and the blurb shown when there is no name. |

