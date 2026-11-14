
- **Context over props:**
  **Decision**: Configuration is read from React Context (the `menuDetail` value) rather than passed as a prop.
  **Rationale**: Many hierarchical detail stacks are rendered by internal components (ResourceExplorer, CrudDataBrowser, ApiBrowser, persona sections) several layers below application code. Threading a boolean through all intermediate layers would require changes at every call site and defeat the purpose of centralizing the choice. The context approach centralizes the decision at the provider level and makes it transparent to consumers.
  **Approved**: pending

- **Default to false:**
  **Decision**: The context defaults to `false` (classic topic view).
  **Rationale**: Existing applications that mount no provider continue to render the classic view, and the menu view is activated only by deliberately mounting a provider or wiring a feature flag. This preserves backward compatibility and keeps the toolkit flag-agnostic rather than changing behavior for existing users.
  **Approved**: pending

- **Cascading-to-covered mapping:**
  **Decision**: When a consumer passes `disclosureStyle: "cascading"` to the router component and the context is `false`, the component maps it to `disclosureStyle: "covered"`.
  **Rationale**: This graceful degradation prevents passing an invalid prop to `HierarchicalTopicDetail` and provides a reasonable fallback: the covered style borrows the cascade's rules for covering, pins, and hover reveal, so it approximates the cascade's visual behavior without the vertical step unique to the menu view.
  **Approved**: pending

- **autoHideTopics passed through, not filtered:**
  **Decision**: The `autoHideTopics` prop is cascade-only and has no meaning in the classic topic view, but it is not filtered out — it is carried along in the destructured rest props and passed to `HierarchicalTopicDetail` unchanged.
  **Rationale**: `HierarchicalTopicDetail` ignores unknown props rather than throwing an error, so this allows consumers to pass superset props without conditional logic of their own; see **cascade-only-props**.
  **Approved**: pending

- **The router is temporary:**
  **Decision**: `HierarchicalDetailView`, its provider, and its hook exist only for the duration of the cascading-vs-classic experiment between `HierarchicalMenuDetail` and `HierarchicalTopicDetail`.
  **Rationale**: Once the experiment concludes, the losing detail-view component and this router file are deleted together; only the winning component remains, and consumers call it directly instead of going through the switch.
  **Approved**: pending

