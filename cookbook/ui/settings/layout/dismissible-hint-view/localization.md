
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| — (no key; literal default parameter value) | "Got It" | `buttonTitle`'s default value when a caller constructs the component without supplying one |

`buttonTitle`'s default value, the English literal `"Got It"`, carries no
localization key or lookup — `text` and any explicit `buttonTitle`
argument are the caller's responsibility to localize (the same treatment
as the sibling Badge recipe ([adhsdk.ingredient.ui.controls.badge](cookbook:2cfe57f0-cdd4-4723-a6e0-2ce4f136ce7f))
gives fully caller-supplied text), but this one default value ships baked
directly into the component itself; a call site that never overrides
`buttonTitle` ships this English literal regardless of the app's locale.

