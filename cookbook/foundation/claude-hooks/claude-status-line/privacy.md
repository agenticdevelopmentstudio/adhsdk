
- **Data collected**: None of its own; an adopted entry holds a command copied from `settings.json`, which may carry a token.
- **Storage**: Owner-only, directories `0700` and entries `0600`, created at final mode before they are visible.
- **Transmission**: None; the type makes no network calls. The registered commands run later under the dispatcher.
- **Retention**: Entries stay until `unregister` or a later `adopt` replaces them; failure records stay until the entry next succeeds or is unregistered.

