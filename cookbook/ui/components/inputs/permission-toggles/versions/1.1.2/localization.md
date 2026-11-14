
| String Key | Default (en) | Context |
|-----------|---------------|---------|
| `permissionToggles.group.label` | CRUD permissions | `aria-label` on the container `role="group"` that announces the whole control. |
| `permissionToggles.title.enable` | Enable {capability} | Button `title` when the capability is off and not blocked; `{capability}` is the raw key (create/read/update/delete). |
| `permissionToggles.title.disable` | Disable {capability} | Button `title` when the capability is on and not blocked. |
| `permissionToggles.title.blockedByParent` | {capability} is not permitted by the parent | Button `title` when the capability is blocked by `parent`. |

The single-letter labels (C, R, U, D) are standard CRUD abbreviations and are not translated. The `title` and `aria-label` strings above are hardcoded in English in the source and SHOULD be externalized to the keys above for a localized build.

