
| Option | Type | Default | Description |
|---|---|---|---|
| `config` | `CharacterConfig` | none — required | Passed to `Scene.init`/`buildScene`; supplies the rig tree, the base `character.inks`/`palette`, and the `character.variants`/`character.crops` tables Scene reads from. |
| `variant` | `String?` (Apple) / `string \| undefined` (web) | `nil`/`undefined` (the "true rig") | Names a `character.variants` entry to fold into the constructed Scene's shapes and inks. |
| `channels` | `Channels` | none — required | Passed to `compose` on every frame; supplies each node's live transform, shape override, ink override, and alpha; any channel absent from the store falls back to that property's built-in default. |
| crop name | `String` | none — required | Passed to `crop`/`cropList`; names a `character.crops` entry whose declared features determine which items of a `DisplayList` are kept. |

Neither source file reads an environment variable, a settings key, or a
build-time flag; every parameter above is supplied by the caller at the call
site.

