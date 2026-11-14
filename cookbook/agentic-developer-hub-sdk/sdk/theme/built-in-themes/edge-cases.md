
- **Unknown ID**: `theme(withID:)` with an ID matching no built-in MUST return `nil`, not trap or return a default. A caller that needs a fallback uses `defaultID` itself.
- **Empty ID**: `theme(withID: "")` MUST return `nil`, since no built-in has an empty `id`.
- **Case difference**: An ID differing only in letter case MUST NOT match, because comparison is exact string equality.
- **Duplicate IDs**: The source does not guard against two entries sharing an ID; `theme(withID:)` would return the first. Uniqueness is enforced only by the `uniqueIDs` test, so a duplicate is caught at test time, not at runtime.
- **Malformed hex literal**: A built-in constant that is not valid hex MUST trap on first access of the theme that contains it (fail-fast), as the `rgb(_:)` doc comment states. Because the themes are `static let`, the trap happens on first use of that constant or of `all`, not at launch.
- **Bright ANSI duplicates**: Several schemes repeat a normal color as its bright variant (Nord bright indices 9 to 13 repeat normal indices 1 to 5, Monokai Pro repeats cyan at indices 4, 6, 12 and 14). That is the data as authored and a port MUST copy it rather than invent distinct brights.
- **Mixed ANSI ordering**: Gruvbox Light places `fbf1c7` (its background tone) at ANSI index 0 and `3c3836` at index 15, the reverse of Solarized Dark's relationship; a port MUST NOT normalize the order.
- **Concurrent access**: Not applicable beyond `immutable-statics`: the values are immutable after lazy initialization, which Swift performs thread-safely, so concurrent readers need no lock.
- **Offline or disconnected**: Not applicable — the catalogue is compiled-in data with no network or file dependency.
- **Null input**: Not applicable — `theme(withID:)` takes a non-optional `String`; the only absent value is the optional return.
- **Boundary values**: The palette length is the only bounded input, and it is fixed at 16 by `ansi-count`; the catalogue size is fixed at 36 by `all-count`.

