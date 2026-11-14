
| Option | Type | Default | Description |
|---|---|---|---|
| `RawFiles` | struct (Apple) / object (web, `unknown` fields) | — | The six unparsed sources the caller supplies: `character`, `rig`, `poses`, `timelines`, `behavior`, `sayings`. |
| directory (Apple only) | `URL` | — | Passed to `RawFiles.read(fromDirectory:)`; the directory MUST contain `character.json` plus the five files it names in its `files` object. |
| `character.json`'s `files` field | object `{rig, poses, timelines, behavior, sayings}` | — | Authored filenames for the other five sources; the loader never hardcodes sibling filenames. |
| `schemaVersion` (each of the six files) | integer | — | MUST equal the loader's built-in `Schema.version` / `SCHEMA_VERSION` constant (currently `1`); not caller-configurable. |

