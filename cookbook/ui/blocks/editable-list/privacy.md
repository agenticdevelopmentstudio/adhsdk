
- **Data collected**: None by the component itself. The component does not collect, log, or transmit any user data beyond what the controller and parent application explicitly define (e.g., search queries, selected row IDs).
- **Storage**: Column widths and details pane divider position are persisted to browser storage (localStorage or equivalent) under keys provided by the parent (`columnWidthsKey`, `details.storageKey`). Selection state, search queries, and filter values are not persisted unless the controller or parent component explicitly implements persistence.
- **Transmission**: The component does not transmit data. Network requests (data fetching, filtering, sorting) are handled by the parent component and controller.
- **Retention**: Persisted storage (column widths, divider position) is retained until explicitly cleared by the application or user action (e.g., browser storage clear).

