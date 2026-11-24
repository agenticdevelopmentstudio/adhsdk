
- **context-value**: The `HierarchicalDetailViewProvider` MUST establish a React Context with the `menuDetail` boolean value provided via the `menuDetail` prop.
- **default-classic**: When no `HierarchicalDetailViewProvider` is rendered, the context MUST default to `false` (classic topic view).
- **route-to-menu-detail**: When context value is `true`, `HierarchicalDetailView` MUST render the `HierarchicalMenuDetail` component and pass all props to it.
- **route-to-topic-detail**: When context value is `false`, `HierarchicalDetailView` MUST render the `HierarchicalTopicDetail` component.
- **cascading-to-covered**: When `disclosureStyle: "cascading"` is passed and context value is `false`, `HierarchicalDetailView` MUST pass `disclosureStyle: "covered"` to `HierarchicalTopicDetail`.
- **cascade-only-props**: When context value is `false`, cascade-only props other than `disclosureStyle` (i.e. `autoHideTopics`) MUST pass through unchanged to `HierarchicalTopicDetail`; `HierarchicalTopicDetail` MUST ignore any prop it does not recognize rather than treating it as an error.
- **preserve-other-props**: All props, including `autoHideTopics`, MUST pass through to the rendered detail view component unchanged; only `disclosureStyle: "cascading"` is rewritten.
- **return-context-value**: The `useHierarchicalMenuDetailView()` hook MUST return the current context value (a boolean).

