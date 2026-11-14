
- **Data collected**: Query strings entered by the user. Result titles and summaries selected or viewed.
- **Storage**: Query and selection data live only in the caller-owned `SearchState` object, held in React state. No persistence to storage, cookies, or local cache.
- **Transmission**: The `SearchState` object is responsible for making search queries to a backend or index. Component itself does not transmit data; `state.setQuery()` and `state.results` handle the exchange. Call site MUST ensure search backend is privacy-compliant.
- **Retention**: `state` is owned and held by the caller, not by `SearchDialog` — closing the dialog (`open: false`) unmounts the component but does not destroy the caller's `SearchState` instance. The component itself resets query and selection each time `open` transitions from `false` to `true` (see **reset-search-state-on-open**); it keeps no history of its own.

Note: This component is a UI container. Privacy compliance depends entirely on the `SearchState` implementation and the backend search service. The component itself is privacy-neutral.

