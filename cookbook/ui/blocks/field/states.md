
| State | Appearance change |
|---|---|
| Default (hint only) | caption, control, then dim-mono `hint` |
| Default (no hint, no error) | caption + control only; no supporting line |
| Error | caption, control, then red-mono `error`; the `hint` is suppressed |
| Focused control | caption + control focus is the control's own affordance; `Field` adds none |
| Disabled control | `Field` adds no dimming (**no-disabled-dimming**); any disabled appearance comes from the control's own styling. The web reference inherits `peer-disabled:opacity-50` from the shared `Label` primitive, but that Tailwind variant only fires for a *sibling* marked `peer` that precedes the styled element, and here the control is a *child* of `Label`, so the rule never matches. It stays because `Label` is shared with callers that do use a `peer` sibling; it is a no-op for `Field` and ports MUST NOT reproduce it. |

