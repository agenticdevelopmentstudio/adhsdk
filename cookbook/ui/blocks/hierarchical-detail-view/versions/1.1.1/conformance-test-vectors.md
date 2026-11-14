
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hdv-001 | context-value | Render `HierarchicalDetailViewProvider` with `menuDetail={true}` | Context value is `true` |
| hdv-002 | default-classic | Render `HierarchicalDetailView` without a provider | Context reads as `false` via `useHierarchicalMenuDetailView()` |
| hdv-003 | route-to-menu-detail | Render `HierarchicalDetailView` with context value `true` | Renders `HierarchicalMenuDetail` component |
| hdv-004 | route-to-topic-detail | Render `HierarchicalDetailView` with context value `false` | Renders `HierarchicalTopicDetail` component |
| hdv-005 | cascading-to-covered | Pass `disclosureStyle: "cascading"` to `HierarchicalDetailView` with context value `false` | Underlying `HierarchicalTopicDetail` receives `disclosureStyle: "covered"` |
| hdv-006 | cascade-only-props | Pass `autoHideTopics={true}` to `HierarchicalDetailView` with context value `false` | Underlying `HierarchicalTopicDetail` receives `autoHideTopics` unchanged and ignores it as an unrecognized prop |
| hdv-007 | preserve-other-props | Pass `levels={[...]}` and `detail={{...}}` to `HierarchicalDetailView` | Underlying view component receives these props unmodified |
| hdv-008 | return-context-value | Call `useHierarchicalMenuDetailView()` inside `HierarchicalDetailViewProvider` with `menuDetail={false}` | Hook returns `false` |
| hdv-009 | preserve-other-props | Pass `disclosureStyle: "covered"` to `HierarchicalDetailView` with context value `false` | Underlying `HierarchicalTopicDetail` receives `disclosureStyle: "covered"` unchanged |
| hdv-010 | route-to-menu-detail | Pass `disclosureStyle: "cascading"` to `HierarchicalDetailView` with context value `true` | Underlying `HierarchicalMenuDetail` receives `disclosureStyle: "cascading"` unchanged |

