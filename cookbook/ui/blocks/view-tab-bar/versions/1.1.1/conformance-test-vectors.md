
| ID | Requirement | Input | Expected |
|----|-------------|-------|----------|
| view-tab-bar-001 | tablist-rendering | `tabs=[{value:"a",label:"Tab A"}]`, `value="a"`, `onChange=()=>{}` | Rendered `<div role="tablist">` containing one `<button role="tab">` |
| view-tab-bar-002 | empty-tabs-omit-tablist | `tabs=[]`, `links=[]` | No `role="tablist"` element in output |
| view-tab-bar-003 | nav-links-rendering | `tabs=[]`, `links=[{href:"/a",label:"Link A"}]` | Rendered `<nav aria-label="views">` containing one `<a href="/a">` |
| view-tab-bar-004 | empty-links-omit-nav | `tabs=[{value:"a",label:"Tab A"}]`, `links=[]` | No `<nav>` element in output |
| view-tab-bar-005 | active-tab-marking | `tabs=[{value:"a",label:"A"},{value:"b",label:"B"}]`, `value="a"` | First tab has `aria-selected="true"`, second has `aria-selected="false"` |
| view-tab-bar-006 | tab-click-callback | `tabs=[{value:"a",label:"A"}]`, `onChange` spy attached | `onChange("a")` called when tab button is clicked |
| view-tab-bar-007 | active-link-marking | `links=[{href:"/a",label:"A",active:true},{href:"/b",label:"B",active:false}]` | First link has `aria-current="page"`, second does not |
| view-tab-bar-008 | active-state-attribute | `tabs=[{value:"a",label:"A"}]`, `value="a"` | Tab button has `data-active=""` attribute |
| view-tab-bar-009 | active-state-attribute | `tabs=[{value:"a",label:"A"}]`, `value="b"` | Tab button does NOT have `data-active` attribute |
| view-tab-bar-010 | tab-role-attribute | `tabs=[{value:"a",label:"A"}]` | Each tab button has `role="tab"` attribute |
| view-tab-bar-011 | icon-tab-label | `tabs=[{value:"a",label:<Icon/>,title:"Icon Label"}]` | Tab button has both `aria-label="Icon Label"` and `title="Icon Label"` attributes |
| view-tab-bar-012 | container-class-merge | `className="custom-class"` | Outermost container div has class `custom-class` applied (via `cn()`) |
| view-tab-bar-013 | layout-spacing | Any valid props | Tablist and nav rows each compute `display: flex`, `align-items: flex-end`, and an equal, non-zero horizontal gap between items; the outer container computes non-zero horizontal padding |
| view-tab-bar-014 | item-styling | Any valid tabs or links | Every tab button and every link resolves to the same style class as each other (identical `className` reference), with only the active item additionally carrying `data-active` |
| view-tab-bar-015 | reactnode-labels | `tabs=[{value:"a",label:<span>Custom</span>}]` | Tab renders ReactNode label content correctly |
| view-tab-bar-016 | empty-tabs-omit-tablist, empty-links-omit-nav | `tabs=[]`, `links=[]`, `className="x"` | Outer container renders with `px-4` and the custom class `x`; no `role="tablist"` element and no `<nav>` element are present |
| view-tab-bar-017 | container-class-merge | `className="custom-class"` | Outer container element has both `px-4` and `custom-class` present simultaneously (merged via `cn()`), not one replacing the other |

