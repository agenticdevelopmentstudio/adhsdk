
| String Key | Default (en) | Context |
|---|---|---|
| `Permission.displayPromptTemplate` | caller-supplied template string | Shown when a `PermissionPrompt` for this `Permission` is presented; carried by the contract, not authored by it |
| `PermissionPrompt.displayPrompt` | caller-supplied, rendered from the template | The concrete, already-filled-in prompt text a UI displays |
| `ChatStatusWordPair.present` | caller-supplied (e.g. `"Thinking"`) | Present-tense status word shown while a `ChatStatus` is active |
| `ChatStatusWordPair.past` | caller-supplied (e.g. `"Thought"`) | Past-tense status word shown once the status resolves |

These four fields are the only user-facing strings the contract itself
carries; every other field is data, not display text. None of the four is
translated by the contract — each is authored and supplied by the host
already in its target locale, matching `ChatStatusWordPair`'s own
documentation that both words are authored, never derived.

