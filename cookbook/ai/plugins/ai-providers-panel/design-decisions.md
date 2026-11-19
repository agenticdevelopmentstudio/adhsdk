
- **Decision**: Reuse each configuration's editor across an add or a remove
  instead of rebuilding every page.
  **Rationale**: Rebuilding would discard the in-progress edits of
  configurations the change never touched.
  **Approved**: pending
- **Decision**: When a configuration's template no longer resolves, clear
  its stored values through the plugin's shared field list.
  **Rationale**: The delete confirmation promises to remove "any API key";
  without the fallback, a configuration whose plugin was removed or whose
  template was renamed would leave its key in secure storage.
  **Approved**: pending
