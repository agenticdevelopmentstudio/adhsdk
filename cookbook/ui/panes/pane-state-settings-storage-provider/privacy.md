
- **Data collected**: The setting values a caller chooses to store as pane overrides; the provider adds nothing of its own.
- **Storage**: In the pane's state store, as JSON text under prefixed keys. The default store for a pane without persistence forgets them when the pane goes away; a project window's store keeps them with the pane.
- **Transmission**: None; the provider performs no I/O beyond the injected store.
- **Retention**: As long as the pane's state is retained, unless `remove` clears the value.

