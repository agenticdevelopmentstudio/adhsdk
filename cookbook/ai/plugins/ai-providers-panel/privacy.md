
- **Data collected**: The field values a person types into a configuration,
  including API keys.
- **Storage**: None of the panel's own. Every value is written through the
  plugin runtime's configuration store, which keeps secret fields in secure
  storage (see the plugin runtime's Privacy).
- **Transmission**: The panel sends nothing itself. The Test Chat sends the
  person's messages to the configured provider, and the model chooser
  fetches the provider's model list with the configuration's key.
- **Retention**: Values persist until the configuration is deleted;
  deleting it clears its stored field values, secrets included, and its
  stored model (**providers-panel-remove-clears-values**).
- **Security-violation handling**: Not applicable: the panel has no
  detection surface.
