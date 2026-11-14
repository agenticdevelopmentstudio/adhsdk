
- **Data collected**: None. The component receives only rendering props
  (`variant`, `size`, `className`, forwarded native button props) and pointer
  events used solely to toggle a local `data-pressed` attribute.
- **Storage**: None. No state is persisted; pressed tracking is transient
  render state that disappears on unmount.
- **Transmission**: None. The component makes no network calls and sends no
  data anywhere.
- **Retention**: Not applicable — nothing is stored.

