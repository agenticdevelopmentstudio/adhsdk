
Not applicable — this is a database extension, not a visual component. The only
lifecycle it has is a jar row's existence: absent, then present after
`insertBrowserJar`, then absent after `deleteBrowserJar`, with the label
mutable while present.

| State | Appearance change |
|-------|------------------|
| Default | Not applicable: no visual surface |

