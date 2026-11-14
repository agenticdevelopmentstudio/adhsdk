
**Decision**: Support compound mode and data-driven mode in one component, with `panes` taking precedence and `children` ignored when `panes` is non-empty.
**Rationale**: A single selection model serves both authoring styles, and the data-driven mode is the simpler call site for static panes. The source comment says children "override" in data-driven mode, but the code never renders them, so the recipe records the behavior and not the comment.
**Approved**: pending

**Decision**: Panes register themselves through context in compound mode instead of the panel scanning its children.
**Rationale**: The sidebar can sit anywhere in the tree and Panes can be wrapped by other components. The cost is that the sidebar fills in after the first effect pass, and a pane that re-registers moves to the end of the list.
**Approved**: pending

**Decision**: Persist the selected id in local storage under a caller-supplied key, read once at mount, written only on user selection, and silent on any storage error.
**Rationale**: Remembering the last pane should never break the panel when storage is disabled or full. Auto-selection is not written back because it is a correction and not a user choice.
**Approved**: pending

**Decision**: Auto-select the first enabled pane whenever the current selection is missing or disabled, guarded so it calls `onSelect` once per target id.
**Rationale**: The guard stops an infinite loop when a controlled parent does not apply the change. It also means a controlled parent that never updates keeps a stale selection while still being told once.
**Approved**: pending

**Decision**: Use the tab roles (`tablist`, `tab`, `tabpanel`) on a sidebar of buttons inside a `nav` landmark.
**Rationale**: It exposes selection state to assistive technology. The source stops short of the full tabs pattern (no arrow-key handling, dangling id references), which is why the open questions on `arrow-key-navigation` and `tab-id-linkage` exist.
**Approved**: pending

