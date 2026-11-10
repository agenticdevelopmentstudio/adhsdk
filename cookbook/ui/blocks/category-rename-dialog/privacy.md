
- **Data collected**: Component does not collect any telemetry or analytics data independently. Host is responsible for any analytics instrumentation.
- **Storage**: Component stores only local state (input text, error message, busy flag) in React state, no localStorage or server storage.
- **Transmission**: Component does not transmit data directly. The `onRename` callback is invoked by the host to transmit renamed node data via host's API.
- **Retention**: Local state is discarded when component unmounts. No persistent data is retained.

