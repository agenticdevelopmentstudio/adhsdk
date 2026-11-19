
- **Decision**: Changing the provider sets the model setting to `""`, the
  new provider's default, instead of keeping the old model id.
  **Rationale**: A model id is meaningful only to the provider that serves it;
  carrying it across a provider change sends a request the new provider
  rejects. `""` already means the provider's default in every feature, and
  the default is set per configuration in the AI Providers panel.
  **Approved**: pending
- **Decision**: One control over a provider source with local and daemon
  implementations, instead of a picker per registry.
  **Rationale**: The two pickers had drifted (one had a model chooser, the
  other a free-text field); a single control with the registry behind an
  interface keeps every panel's provider and model choice the same.
  **Approved**: pending
- **Decision**: The daemon source takes an optional plugin manager.
  **Rationale**: The Kitchen has one and can show model lists and names;
  Stenographer links the same code without one, and its panels must still
  show and set a provider and the stored model.
  **Approved**: pending

