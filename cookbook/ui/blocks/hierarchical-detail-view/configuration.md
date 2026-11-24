
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `menuDetail` | `boolean` | `false` | Passed to `HierarchicalDetailViewProvider` to select the cascading menu view (`true`) or classic topic view (`false`) |
| `children` | `ReactNode` | — | Child components to render within the provider context |

`HierarchicalDetailView` itself takes `ComponentProps<typeof HierarchicalMenuDetail>`. This is not a full superset of `HierarchicalTopicDetail`'s props: `HierarchicalTopicDetail`'s `surfaceScope` prop is absent from `HierarchicalMenuDetail`, so it cannot be passed to the router at all, in either context. The props `HierarchicalMenuDetail` does declare are documented once, on `HierarchicalMenuDetail` ([adhsdk.ingredient.ui.blocks.hierarchical-menu-detail](cookbook:aaebd90e-991f-4133-a12d-0783586eae5a)), rather than restated here; see **preserve-other-props** and **cascading-to-covered** for how the router narrows that surface under the classic view.

