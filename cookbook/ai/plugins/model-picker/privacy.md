
- **Data collected**: None of the component's own. The context carries the
  provider's API key so the chooser can fetch the provider's live model list.
- **Storage**: None. The component stores no setting; the caller decides what
  to do with a chosen model.
- **Transmission**: The live model list, model metadata, descriptions,
  popularity and ranks are fetched through the provider model stores the
  chooser uses, with the context's key for the provider's own list; the
  component sends nothing else.
- **Retention**: The context lives only while the popover is open.
- **Security-violation handling**: Not applicable: the component has no
  detection surface; a key the provider rejects only leaves the live list
  unloaded.

