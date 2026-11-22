
The module authors two English strings of its own; every other message a caller sees comes
from the backend's response body.

| String Key | Default (en) | Context |
|-----------|---------------|---------|
| none | `GET /v1/access/features returned a malformed feature list` | Thrown by `listFeatures` when the response fails its shape or page check |
| none | `<url>: has_more is set but the last row carries no id to page from` | Thrown by the shared pager used by `listRoles` |

There is no catalog, key or i18n call in the module; both strings are hardcoded literals,
stated as fact rather than a gap.

