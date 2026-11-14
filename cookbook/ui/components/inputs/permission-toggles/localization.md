
| String Key | Default (en) | Context |
|-----------|---------------|---------|
| `permissionToggles.group.label` | CRUD permissions | `aria-label` on the container `role="group"` that announces the whole control. |
| `permissionToggles.capability.create` | create | Localized capability name inserted into `{capability}` in the title strings. |
| `permissionToggles.capability.read` | read | Localized capability name inserted into `{capability}`. |
| `permissionToggles.capability.update` | update | Localized capability name inserted into `{capability}`. |
| `permissionToggles.capability.delete` | delete | Localized capability name inserted into `{capability}`. |
| `permissionToggles.title.enable` | Enable {capability} | Button `title` when the capability is off and not blocked; `{capability}` is the raw key (create/read/update/delete) in the source; a localized build SHOULD insert the capability name from the per-capability keys below. |
| `permissionToggles.title.disable` | Disable {capability} | Button `title` when the capability is on and not blocked. |
| `permissionToggles.title.blockedByParent` | {capability} is not permitted by the parent | Button `title` when the capability is blocked by `parent`. |

The single-letter labels (C, R, U, D) are standard CRUD abbreviations and are not translated. The `title` and `aria-label` strings above are hardcoded in English in the source and SHOULD be externalized to the keys above for a localized build.

