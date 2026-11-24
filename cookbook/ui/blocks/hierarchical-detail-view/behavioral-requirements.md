
- **context-value**: The `HierarchicalDetailViewProvider` MUST establish a React Context with the `menuDetail` boolean value provided via the `menuDetail` prop.
- **default-classic**: When no `HierarchicalDetailViewProvider` is rendered, the context MUST default to `false` (classic topic view).
- **route-to-menu-detail**: When context value is `true`, `HierarchicalDetailView` MUST render the `HierarchicalMenuDetail` component and pass all props to it.
- **route-to-topic-detail**: When context value is `false`, `HierarchicalDetailView` MUST render the `HierarchicalTopicDetail` component.
- **cascading-to-covered**: When `disclosureStyle: "cascading"` is passed and context value is `false`, `HierarchicalDetailView` MUST pass `disclosureStyle: "covered"` to `HierarchicalTopicDetail`.
- **preserve-other-props**: All props, including the cascade-only `autoHideTopics`, MUST pass through to the rendered detail view component unchanged; only `disclosureStyle: "cascading"` is rewritten, and only when context value is `false`. Whether `HierarchicalTopicDetail` ignores a prop it does not recognize is that component's own behavior, not a requirement of this router (see [adhsdk.recipe.ui.blocks.hierarchical-topic-detail](cookbook:0bba1f5b-bc8d-4f76-b1c9-329b627f7ee8)).
- **return-context-value**: The `useHierarchicalMenuDetailView()` hook MUST return the current context value (a boolean).

