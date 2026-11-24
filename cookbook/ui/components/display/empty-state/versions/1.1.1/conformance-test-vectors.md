
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| empty-state-001 | title | `title="No items"` | Title text "No items" appears centered in container |
| empty-state-002 | dashed-border | Default props | Container has visible dashed border |
| empty-state-003 | minimum-height | Default props | Container height is at least 160px |
| empty-state-004 | optional-icon, icon-size | `icon={<Icon />}` | Icon is rendered above title and its wrapper constrains it to 24×24px |
| empty-state-005 | optional-description | `description="Try adding an item"` | Description text appears below title |
| empty-state-006 | optional-action | `action={<Button>Create</Button>}` | Action button appears below description |
| empty-state-007 | classname | `className="bg-red-100"` | Custom class is applied to container |
| empty-state-008 | centered-content | `title="Centered"` rendered inside a container constrained to 320px width | Title text is centered horizontally and vertically within the 320px-wide container |
| empty-state-009 | optional-icon, optional-description, optional-action | `title`, no other props | Only title is rendered; description, action, and icon wrappers are absent |
| empty-state-010 | non-optional-title | Omit the `title` prop entirely | TypeScript compiler rejects the call with a type error (`title` is a required, non-optional prop) |

