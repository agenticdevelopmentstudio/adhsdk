
- **Data collected**: None. This component does not collect user data.
- **Storage**: None. The fetched content is held in React state for rendering only.
- **Transmission**: The component fetches content via HTTP(S) from the injected `source.baseUrl`. Transmission is governed by the host application's endpoint configuration and network layer (e.g., auth headers in `source.fetchInit`).
- **Retention**: Content is not persisted; it is discarded when the component unmounts or when a different document is selected.

