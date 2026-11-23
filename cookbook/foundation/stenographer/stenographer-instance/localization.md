
The `ResolutionError` descriptions are hardcoded English strings and are not localized. They reach a person through the stderr line that `current` writes before exiting.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `invalidName` | `instance name '<name>' must match [a-z0-9][a-z0-9-]{0,31}` | Name fails the pattern. |
| `reservedName` | `instance name '<name>' is reserved: com.agenticdevelopmentstudio.stenographer.<name> already names something else` | Name is in `reservedNames`. |
| `undefined` | `instance '<name>' is not defined (no <path>); create it with scripts/stenographer_instance.py create` | No definition file. |
| `unreadable` | `instance definition <path> is unreadable: <reason>` | Read or decode failed. |
| `nameMismatch` | `instance definition <file>.json declares name '<declared>'` | Declared name differs from the file name. |
| `relativeDataRoot` | `instance dataRoot '<root>' must be an absolute path` | Data root does not start with `/`. |
| `invalidPort` | `instance httpPort <port> must be 1024-65535 and not one of 22848, 22849, 22850, 22871` | Port out of range or reserved; the reserved list is sorted ascending. |
| `overlapsInstalledState` | `instance dataRoot '<root>' overlaps <protected>, which the installed Stenographer owns` | Data root overlaps a protected root. |
| `overlapsAnotherInstance` | `instance dataRoot '<root>' overlaps instance '<instance>''s dataRoot '<otherRoot>'` | Data root overlaps another definition's. |
| `portTakenByAnotherInstance` | `instance httpPort <port> is already instance '<instance>''s httpPort` | Another definition declares the same port. |
| `socketPathTooLong` | `instance socket path <path> is <bytes> bytes; the limit is under 104` | Socket path is 104 bytes or more. |
| (stderr prefix) | `stenographer: <description>` | Written by `current` before exit 78. |

