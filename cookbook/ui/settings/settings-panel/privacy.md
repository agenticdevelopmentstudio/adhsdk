
- **Data collected**: None of its own. The component holds only the
  caller-supplied or default-constructed descriptor (title, subtitle,
  icon, disabled flag, section and heading) and its own content view.
  The descriptor's text fields are shown in the sidebar exactly as set;
  nothing filters them, so a caller MUST NOT put a secret value (a key,
  token or password) in a title or subtitle, only a label such as
  "API key set".
- **Storage**: Not applicable — this component performs no read/write to
  disk or any other store.
- **Transmission**: Not applicable — no networking call appears anywhere
  in this component.
- **Retention**: Not applicable — the descriptor is in-memory state
  retained only for the panel instance's own lifetime; this component
  persists nothing.

