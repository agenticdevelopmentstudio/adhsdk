
- **Null / empty input**: An empty persisted list makes `restore()` open nothing; an empty-string key is a key like any other.
- **Boundary values**: A key already in the list when its window opens (restore, or a window closed while the app was quitting) is not appended twice.
- **Concurrent access**: Main actor only; `open`, `bringForward` and `onClose` run on it.
- **Error states**: The set has no errors of its own: an owner that cannot open a key returns `nil` (and logs why), and restore drops that key.
- **Offline / disconnected state**: Not applicable: no network.
- **Cancellation**: Not applicable: every call is synchronous.
- **Quit with windows open**: An owner whose window manager suppresses `onClose` for closes made while the app terminates (the project window manager does) keeps those keys in the list, so they reopen at the next launch.

