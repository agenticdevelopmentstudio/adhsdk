
- **Data collected**: The current numeric value only (no sensitive metadata).
- **Storage**: Value is maintained in component state during the session; not persisted by the component itself.
- **Transmission**: No data is transmitted by the component; the consumer (`onChange` handler) determines what is done with the value.
- **Retention**: Value is ephemeral within the component lifecycle; retention depends on the consuming application.

