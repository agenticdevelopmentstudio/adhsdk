
- **open-new**: `open(key:activates:)` for a key with no open window MUST call `open(key, activates, onClose)` once; when it returns a controller the set MUST record it as the key's controller, append the key to the persisted list if absent, and return it.
- **open-declined**: When `open` returns `nil`, the set MUST return `nil`, record no controller and leave the persisted list unchanged.
- **open-existing**: `open(key:activates:)` for a key whose window is open MUST call `bringForward` with that key's controller, MUST NOT call `open`, and MUST return the same controller.
- **close-forgets**: Calling the `onClose` handed to `open` for a key MUST drop the key's controller and remove the key from the persisted list; the next `open` of that key opens a new window.
- **order**: The persisted list MUST hold each key once, in the order the keys were first opened; `keys` MUST return it.
- **restore**: `restore()` MUST call `open(key:activates: false)` for every key in the persisted list, in list order, and MUST remove from the list every key whose `open` returned `nil`, keeping the order of the rest.
- **storage**: The list MUST be stored as `[String]` in the `UserSetting<[String]>` the owner passes, so an owner keeps its existing setting name and stored values.
- **main-actor**: The set MUST be used on the main actor only.

