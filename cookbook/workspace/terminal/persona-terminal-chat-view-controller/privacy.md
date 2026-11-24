
- **Data collected**: The persona text, the chosen provider id and model, and the
  Connect flag, per pane. Chat messages and tool results are held by the session.
- **Storage**: The four choices in the pane state store, which is an injected `PaneStateStore`: a project window supplies one backed by its `pane_state` rows, and an `EphemeralPaneStateStore` forgets when the pane goes away. Provider API keys are resolved from Settings at turn time and are not
  stored here.
- **Transmission**: Messages and tool results go to the chosen LLM provider; the
  live model list request sends the provider's API key to its base URL. When the
  Terminal Chat is connected to a private terminal, the persona sees only the
  terminal's privacy words (per the source comment; enforced outside this file).
- **Retention**: Choices stay until changed or the pane is removed (or, with an ephemeral store, until the pane goes away); chat history
  belongs to the session.

