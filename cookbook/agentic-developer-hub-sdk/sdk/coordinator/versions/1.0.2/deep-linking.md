
Not applicable: `PersonaChatCoordinator` exposes no URL scheme or route of
its own. `baseURL` is an API root supplied by the caller, not a
deep-linkable app URL, and neither source file parses or constructs a
`{{app_scheme}}://` or `https://{{app_domain}}/` link.

