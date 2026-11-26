
- Null and empty input: an empty or whitespace-only command to `adopt(_:)` returns nil and writes nothing (MUST); an empty `errors/<name>` file reads as nil (MUST); an empty name is invalid for every operation that checks it (MUST).
- Malformed input: a version line with a non-numeric remainder is skipped and the scan continues (MUST); an entry file that is not valid UTF-8 reads as absent (**entry-utf8**).
- Boundary values: `adopted-10` and `adopted-2` are adopted names, `adopted-` and `adopted-x` are not (MUST); a command of just `python3  # claudehelpers-statusline` (or `sh  # …`) has no path and is not the dispatcher's (MUST).
- Concurrent access: this type takes no lock itself; callers hold the shared `.settings.lock` across any sequence that reads the slot and writes entries (**settings-lock-held**).
- Error states: a failed file operation throws; `lastError(of:)`, `entries()` and `entry(named:)` swallow read failures and return nil or an empty list (MUST).
- Offline or disconnected state: not applicable; the type touches only local files.
- Name collision across kinds: `register` removes a same-named entry of the other kind, so one name is never both renderer and tap (MUST).
- A tool never edits another's entry: `register` and `unregister` are called only with the calling tool's own name, except adoption's removal of earlier `adopted*` renderers (**own-name-only**).

