
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `STENOGRAPHER_INSTANCE` | environment variable | unset | Names the instance; wins over the argument; an empty value selects the default. |
| `-instance <name>` | process argument | absent | Names the instance when the environment variable is unset. |
| `home` | `URL` | the current user's home directory (for `current`) | The root of the definitions directory and of the protected roots; passed explicitly to `resolve`, `validate`, `definitionsDirectory` and `protectedRoots`. |
| `<name>.json` | definition file | none | `{"name", "dataRoot", "httpPort"}` in the definitions directory, written by `scripts/stenographer_instance.py create`. |

The type reads no settings key and takes no injected dependency besides `home`; it uses the real file system through `FileManager.default` and `realpath`.

