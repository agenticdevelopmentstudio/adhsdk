
- **Data collected**: The current numeric value only (no sensitive metadata).
- **Storage**: The component keeps no state of its own; the controlled `value` prop is owned by the consumer and is not persisted by the component itself.
- **Transmission**: No data is transmitted by the component; the consumer (`onChange` handler) determines what is done with the value.
- **Retention**: Value is ephemeral within the component lifecycle; retention depends on the consuming application.

