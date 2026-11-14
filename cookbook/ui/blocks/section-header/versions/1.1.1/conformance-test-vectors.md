
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| section-header-001 | render-title | `title="All ecosystems"` | h2 heading with text "All ecosystems" rendered in left section |
| section-header-002 | support-eyebrow | `eyebrow="Section"`, `title="Title"` | Eyebrow text rendered above title in dim monospace; title rendered below in gold monospace |
| section-header-003 | support-eyebrow | `title="Title"` (no eyebrow) | Only title rendered; eyebrow slot absent from DOM |
| section-header-004 | support-help | `help={<div>Help content</div>}`, `title="Title"` | Help button visible in right section |
| section-header-005 | support-help | `title="Title"` (no help) | Help button not rendered |
| section-header-006 | display-help-popover | Help button present, user clicks help trigger | Popover appears; popover content (help prop) is visible; popover positioned below trigger, aligned right |
| section-header-007 | display-help-popover | Help button present, user presses Enter on focused help trigger | Popover opens (same as click) |
| section-header-008 | label-help-trigger | Help button rendered | Button has `aria-label="About this section"` |
| section-header-009 | support-actions | `actions={<button>Action</button>}`, `title="Title"` | Actions content rendered in right section, before help button |
| section-header-010 | support-actions | `title="Title"` (no actions) | Actions slot absent from DOM |
| section-header-011 | apply-custom-class | `className="my-custom-class"`, `title="Title"` | Root container has both default flex classes and "my-custom-class" |
| section-header-012 | maintain-layout-order | All props provided | Left section (title area) precedes right section (actions + help) in visual layout; justified to opposite edges |
| section-header-013 | display-help-popover | Help button present, user presses Space on focused help trigger | Popover opens (same as click/Enter) |
| section-header-014 | display-help-popover | Popover open, user presses Escape | Popover closes and focus returns to the help trigger (per accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)), accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))) |
| section-header-015 | display-help-popover | Help button activated a second time while the popover is open | Popover closes; toggle state is reflected via `aria-expanded` (per accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))) |

