
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| editor-toolbar-001 | toolbar-role | Render component with default props | `<div role="toolbar" ...>` is present in the DOM |
| editor-toolbar-002 | aria-label-default | Render component without `ariaLabel` prop | Element has `aria-label="Editor toolbar"` |
| editor-toolbar-003 | aria-label-prop | Render with `ariaLabel="Custom toolbar"` | Element has `aria-label="Custom toolbar"` |
| editor-toolbar-004 | render-children | Render with `children={<button>Bold</button>}` | Button element is rendered inside the toolbar |
| editor-toolbar-005 | class-name-merge | Render with `className="custom-class"` | Element has both default classes and `custom-class` applied |
| editor-toolbar-006 | flex-layout | Unit test: render component and inspect the rendered `class` attribute | Class attribute contains `flex` |
| editor-toolbar-007 | vertical-center | Unit test: render component and inspect the rendered `class` attribute | Class attribute contains `items-center` |
| editor-toolbar-008 | child-gap | Unit test: render component and inspect the rendered `class` attribute | Class attribute contains `gap-1.5` |
| editor-toolbar-009 | vertical-center | Playwright: render with tall and short children in a browser; measure each child's bounding-box vertical center | All children's vertical centers match within a 1px tolerance; no baseline drift |
| editor-toolbar-010 | child-gap | Playwright: render with multiple child elements in a browser; measure the gap between adjacent children | Horizontal gap is 6px ± 1px |
| editor-toolbar-011 | child-gap | Playwright: render with `className="gap-4"` and multiple children; measure the gap between adjacent children | Horizontal gap is 16px ± 1px — the caller's `gap-4` overrides the default `gap-1.5` (tailwind-merge resolves the conflict; the later class wins) |

