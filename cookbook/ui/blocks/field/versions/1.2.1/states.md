
| State | Appearance change |
|---|---|
| Default (hint only) | caption, control, then dim-mono `hint` |
| Default (no hint, no error) | caption + control only; no supporting line |
| Error | caption, control, then red-mono `error`; the `hint` is suppressed |
| Focused control | caption + control focus is the control's own affordance; `Field` adds none |
| Disabled control | no dimming from `Field` itself; the wrapping `Label` carries `peer-disabled:opacity-50`, but that Tailwind variant only fires for a *sibling* marked `peer` that precedes the styled element — here the control is a *child* of `Label`, not a preceding sibling, so the rule never matches. Any disabled appearance comes from the control's own styling. |

