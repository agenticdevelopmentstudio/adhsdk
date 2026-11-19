
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
  **Rationale**: A host with a plugin manager can show model lists and names;
  a host that links the same code without one must still show and set a
  provider and the stored model in its panels.
  **Approved**: pending
- **Decision**: The control replaces the per-panel provider pickers
  (`LLMPickerView`, `DaemonProviderPickerView`, and the "Choose…"/"Try…"
  rows and free-text model fields that panels built themselves), which are
  deleted rather than kept beside it.
  **Rationale**: Keeping the predecessors would let panels drift apart again;
  one control is the only provider and model choice a panel can reach for.
  **Approved**: pending
- **Decision**: `unit-test-coverage` failing is accepted debt. The tests in
  `ProviderModelPickerViewTests.swift` cover the popup order, the
  provider-change reset and the stored-model display; re-choosing the same
  provider, a leading choice disabling the model row, the stale-selection
  rule, the local source's default model and external-change refresh have
  none. Adding tests for those rules to that file clears it.
  **Rationale**: The control replaced working pickers whose behavior it
  matches; the untested rules are small and covered by the conformance
  vectors until the tests land.
  **Approved**: pending
- **Decision**: `no-hardcoded-strings` failing is accepted debt: the default
  labels and "Choose a Model" are English literals in the source. Looking
  them up by the string keys in the Localization table clears it.
  **Rationale**: Callers already pass their own labels, so only the defaults
  are unlocalized.
  **Approved**: pending

