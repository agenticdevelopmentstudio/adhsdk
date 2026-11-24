
Not applicable — this is a headless session object, not a visual component. The runtime state is carried by `ChatSessionState` (`connecting`, `ready`, `responding`, `failed`, `closed`), which this type does not store: it emits whatever its owner sets with `setState`, plus `.ready` after each `.result` and `.closed` from `close()`.

