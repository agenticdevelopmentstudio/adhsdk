
| Flag Key | Default | Description |
|----------|---------|-------------|
| `{{app_prefix}}.hierarchical_menu_detail_view` | `false` | A host app MAY wire any boolean feature flag to the `menuDetail` prop of `HierarchicalDetailViewProvider` to enable the cascading menu view for A/B testing or gradual rollout. The toolkit itself is flag-agnostic; for example, the adh apps wire this to their own `use_hierarchical_menu_details_view` flag. |

