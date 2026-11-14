
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| app-tabs-001 | render-items | `items=[{id:"tab1", label:"Tab 1"}, {id:"tab2", label:"Tab 2"}]` | Both tabs render as buttons; text content matches labels. |
| app-tabs-002 | mark-active-tab | `items=[{id:"tab1", label:"T1"}, {id:"tab2", label:"T2"}]`, `value="tab1"` | Tab with id="tab1" has `aria-selected="true"` and `data-active="true"`; tab with id="tab2" has `aria-selected="false"` and no `data-active` attribute. |
| app-tabs-003 | render-icon-if-provided | `items=[{id:"tab1", label:"Tab", icon:<IconComponent />}]` | Icon is rendered inside the tab button alongside the label. |
| app-tabs-004 | invoke-callback-on-click | `items=[{id:"tab1", label:"T1"}]`, `onValueChange={spy}` | Clicking the tab invokes `onValueChange("tab1")`. |
| app-tabs-005 | render-end-item-if-provided | `endItem={id:"settings", label:"Settings"}` | EndItem renders as a button positioned at the trailing edge of the tab bar, after all `items` tabs. |
| app-tabs-006 | respect-end-item-active-state | `items=[{id:"tab1", label:"Tab"}]`, `value="tab1"`, `endItem={id:"settings", label:"Settings", active: true}` | Tab 1 is active per `value`; endItem is active per its own `active` property; they are independently active. |
| app-tabs-007 | apply-role-tablist | Any valid props | Root `<div>` has `role="tablist"`. |
| app-tabs-008 | apply-role-tab-to-items | Any valid props | Every rendered button has `role="tab"`. |
| app-tabs-009 | apply-class-name | `className="custom-class"` | Root container's class list contains `custom-class`. |
| app-tabs-010 | no-content-panels | Any valid props | All tabs are self-contained `<button>` elements; no `role="tabpanel"` (or equivalent content-panel element) exists anywhere in the rendered output. |
| app-tabs-011 | invoke-callback-on-click | `items=[{id:"tab1", label:"T1"}]`, `endItem={id:"settings", label:"Settings"}`, `onValueChange={spy}` | Clicking `endItem` invokes `onValueChange("settings")`, using the same click handler as any other tab. |

