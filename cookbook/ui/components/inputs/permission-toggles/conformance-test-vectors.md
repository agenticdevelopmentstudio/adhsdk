
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| perm-001 | render-four-buttons | `value={create: false, read: false, update: false, delete: false}` | Four buttons rendered, labeled C, R, U, D. |
| perm-002 | toggle-on-click | `value={create: false, read: false, update: false, delete: false}`, user clicks C button | `onChange` called with `{create: true, read: false, update: false, delete: false}`. |
| perm-003 | aria-pressed-reflects-on | C button with `value.create === true`, no `parent` | Button has `aria-pressed="true"`. |
| perm-004 | aria-pressed-reflects-on | C button with `value.create === false`, no `parent` | Button has `aria-pressed="false"`. |
| perm-005 | title-describes-action | C button enabled, `value.create === false` | Title reads "Enable create". |
| perm-006 | title-describes-action | C button enabled, `value.create === true` | Title reads "Disable create". |
| perm-007 | enforce-parent-ceiling | `parent={create: false, read: true, update: true, delete: true}`, user clicks C button | Button is disabled. `onChange` not called. |
| perm-008 | clamp-emitted-values | `parent={create: false, read: true, update: true, delete: true}`, `value={create: true, read: true, update: true, delete: true}`, user clicks R button | `onChange` called with `{create: true, read: false, update: true, delete: true}` — the pre-existing `create: true` violation of `parent` passes through unchanged; only the clicked capability (`read`) is inverted. |
| perm-009 | enforce-parent-ceiling | `parent={create: false, read: true, update: true, delete: true}` | C button has the `disabled` attribute set (not focusable, not clickable) and renders in the blocked visual state. |
| perm-010 | title-describes-action | C button blocked by parent | Title reads "create is not permitted by the parent". |
| perm-011 | disabled-blocks-toggle | `disabled={true}`, user clicks any button | No button responds. `onChange` not called. |
| perm-012 | group-role-and-label | Component rendered | Container has `role="group"` and `aria-label="CRUD permissions"`. |
| perm-013 | single-letter-labels | Component rendered | Buttons display text content C, R, U, D. |
| perm-014 | aria-pressed-reflects-on | `parent={create: false, read: true, update: true, delete: true}`, `value.create === true` | C button has `aria-pressed="false"` — it reflects the displayed `on` state, not the raw `value.create`. |
| perm-015 | enforce-parent-ceiling | `parent={create: false, read: false, update: false, delete: false}` | All four buttons render disabled. No click produces an `onChange` call. |
| perm-016 | clamp-emitted-values | `parent` omitted (`undefined`), user clicks any button | Button is enabled; the capability toggles normally; `onChange` called with only that capability inverted. |
| perm-017 | disabled-blocks-toggle, enforce-parent-ceiling | `disabled={true}` and the C button is also blocked by parent | Button is disabled by both conditions; behavior is identical to either condition alone. `onChange` not called. |
| perm-018 | toggle-on-click | `value={create: false, read: false, update: false, delete: false}`, user clicks C three times in rapid succession | `onChange` called three times, once per click, each call reflecting the click-time value of `create`; no debouncing. |
| perm-019 | toggle-on-click | Component unmounted while the border/background/text color transition is in progress | No error is thrown; the interrupted CSS transition has no observable effect on application state. |

