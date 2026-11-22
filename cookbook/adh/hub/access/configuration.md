
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `target` | string or `AccessTarget` | none, required on every call | A bare workspace slug, `{ workspace }` or `{ ecosystem }`; sent as the single `workspace` or `ecosystem` query parameter. |
| `opts` (listSubjects) | `{ q?, limit? }` | `{}` | `q` searches email, name or slug and is omitted when empty; `limit` is sent only when given. |
| `scope` (listAssignments) | `{ feature, itemId }` | omitted, workspace-wide listing | When given, narrows the listing to one item and adds `feature` and `item_id`. |
| `input` (createRole) | `AccessRoleInput` | none, required | `slug`, `name`, optional `description`, optional `defaultFor` (`""`, `"customer"` or `"persona"`), and `grants`. |
| `patch` (updateRole) | `Partial<Omit<AccessRoleInput, "slug">>` | none, required | Any subset of `name`, `description`, `defaultFor` and `grants`. |
| `input` (putAssignment) | `AccessAssignmentInput` | none, required | `subjectKind` (`customer`, `persona` or `team`), `subjectId`, optional `feature` and `itemId`, and `roleId`. |
| `q` (effective) | `{ feature, subjectKind, subjectId, itemId? }` | none, required | `subjectKind` is `customer` or `persona`; `itemId` is sent only when non-empty. |
| base route | constant `/api/v1/access` | fixed | Not injectable; every path is built from it. |
| page size | constant `100` | fixed | `listFeatures` sends `limit=100`; `listRoles` pages at `V1_PAGE_MAX`. |
| `ACCESS_FEATURES` | read-only list of `AccessFeatureRow` | the two-entry fallback | For a caller's catch block; never applied by this client. |

