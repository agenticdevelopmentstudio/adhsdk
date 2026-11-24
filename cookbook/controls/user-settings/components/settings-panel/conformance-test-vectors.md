
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| settings-panel-001 | compound-mode-children, pane-renders-when-selected, auto-select-first-enabled | Compound example with General, Notifications and a disabled Security pane; no `selectedId`, no `defaultPaneId` (test: "selects the first enabled pane by default") | `general body` is in the document; `notifications body` is not |
| settings-panel-002 | row-click-selects, uncontrolled-selection | Same example; click the tab named Notifications (test: "switches pane when sidebar row is clicked") | `notifications body` is shown and `general body` is gone |
| settings-panel-003 | sidebar-grouping, sidebar-section-title, sidebar-nav | Same example; inspect the navigation named `Settings sections` (test: "groups panes by section, unsectioned first") | Exactly one section title, `Preferences`; rows in order General, Notifications, Security |
| settings-panel-004 | row-disabled, row-click-disabled-ignored | Same example; click the Security tab (test: "disables a pane and prevents selection") | The tab is disabled; `security body` never appears |
| settings-panel-005 | controlled-selection, select-notifies | `selectedId="notifications"` with an `onSelect` spy; click the General tab (test: "respects controlled selectedId and calls onSelect on click") | `onSelect` is called with `general`; `notifications body` is still shown |
| settings-panel-006 | persist-write, persist-read-once, initial-selection | `persistKey="t1"`; click Notifications; unmount; mount again with the same key (test: "persists selection to localStorage when persistKey is set") | Storage item `aws-settings:t1` equals `notifications`; the second mount shows `notifications body` |
| settings-panel-007 | data-mode-activation, data-mode-layout, data-mode-body, data-mode-descriptors | `panes` with entries A and B, `sidebarTitle="Account"`, no children; click tab B (test: "renders panes via the data-driven API") | `body a` is shown first; after the click `body b` is shown |
| settings-panel-008 | uncontrolled-selection, select-notifies | Compound panel with panes X and Y and an `onSelect` handler; click tab Y (test: "uncontrolled mode tracks internal selection across clicks") | `y body` is shown |
| settings-panel-009 | context-required | Render `SettingsPanel.Pane` with no panel ancestor | Rendering throws an Error with message `SettingsPanel subcomponents must be rendered inside <SettingsPanel>` (derived from the source; no test beside the source covers it) |
| settings-panel-010 | data-mode-ignores-children | `panes` with entry A and a child element `child text` | `child text` is not in the document; `body a` is |
| settings-panel-011 | auto-select-first-enabled, auto-select-notifies, auto-select-no-persist | Controlled `selectedId="gone"`, panes A (enabled) and B, `persistKey="t2"`, an `onSelect` spy | `onSelect` is called once with `A`; storage item `aws-settings:t2` is absent |
| settings-panel-012 | auto-select-none-enabled | Panes A and B both `isDisabled` | No pane body renders and `onSelect` is not called |
| settings-panel-013 | persist-failure-tolerated | Local storage read and write both throw; `persistKey="t3"`, `defaultPaneId="b"`; click tab A | No error escapes; initial selection is `b`; A becomes selected |
| settings-panel-014 | persist-write, controlled-selection | Controlled `selectedId="a"`, `persistKey="t4"`; click tab B | Storage item `aws-settings:t4` equals `b`; selection stays `a` |
| settings-panel-015 | sidebar-title, sidebar-title-omitted | `Sidebar` with `title="Local"` inside a panel with `sidebarTitle="Global"`; then a panel with neither | The first renders one `h2` reading `Local`; the second renders no `h2` |
| settings-panel-016 | row-icon, row-label | Pane with `icon` set and a pane without | The first row has a span `aws-panel__sidebar-icon`; the second row does not |
| settings-panel-017 | registration-replaces-by-id | Compound panes P, Q, R; change P's `title` | P's row moves after R in the sidebar |
| settings-panel-018 | auto-select-once | Controlled `selectedId="gone"`, parent never updates, `onSelect` spy; rerender twice | `onSelect` is called once, not on each render |

