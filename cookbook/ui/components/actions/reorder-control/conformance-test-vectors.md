
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| reorder-control-001 | render-up-button | canMoveUp=true, onMoveUp callback | Up button renders; clicking it calls onMoveUp |
| reorder-control-002 | render-down-button | canMoveDown=true, onMoveDown callback | Down button renders; clicking it calls onMoveDown |
| reorder-control-003 | disable-up-at-boundary | canMoveUp=false | Up button renders with disabled attribute; click does not call onMoveUp |
| reorder-control-004 | disable-down-at-boundary | canMoveDown=false | Down button renders with disabled attribute; click does not call onMoveDown |
| reorder-control-005 | boundary-buttons-persist | canMoveUp=false, canMoveDown=true (first row) | Up button is present but disabled; down button is enabled |
| reorder-control-006 | boundary-buttons-persist | canMoveUp=true, canMoveDown=false (last row) | Down button is present but disabled; up button is enabled |
| reorder-control-007 | arrow-icons | default | Arrow-shaped up and down icons are rendered, visually distinct from chevron/disclosure icons |
| reorder-control-008 | group-role, group-aria-label | default | Outer span has role="group" and aria-label containing "Reorder" |
| reorder-control-009 | button-aria-labels, button-titles | default | Both buttons have aria-label and title attributes with "Move up" or "Move down" text |
| reorder-control-010 | custom-subject-support | subject="Work item" | Both button aria-labels and group aria-label include "Work item" text |
| reorder-control-011 | busy-state-appearance | busy=true | Group container opacity is 60%; aria-disabled set on both buttons; group carries aria-busy, not aria-disabled |
| reorder-control-012 | aria-disabled-while-busy | busy=true | aria-disabled attribute is set; disabled attribute is not set (buttons remain in tab order) |
| reorder-control-013 | busy-click-guard | busy=true, user clicks up or down button | onMoveUp and onMoveDown are not called; component ignores click |
| reorder-control-014 | decorative-icons | default | Arrow icons have aria-hidden="true" |
| reorder-control-015 | compact-transparent-buttons | default | Buttons render with no visible background fill or border and compute to 28×28px |
| reorder-control-016 | custom-class-name | className="custom-class" | Custom class is applied to outer container alongside default classes |
| reorder-control-017 | overlapping-disabled-states | busy=true, canMoveUp=false | Up button has both the disabled attribute and aria-disabled set at the same time |
| reorder-control-018 | group-aria-busy | busy=true, then busy=false | Group has aria-busy="true" while busy; attribute is absent once busy is false |
| reorder-control-019 | empty-subject-no-suffix | subject=undefined | Button aria-labels are exactly "Move up" / "Move down"; group aria-label is exactly "Reorder" (no trailing space) |
| reorder-control-020 | both-boundaries-disabled | canMoveUp=false, canMoveDown=false | Both buttons render disabled; component does not throw |
| reorder-control-021 | busy-to-idle-recovery | busy=true transitioning to busy=false | Opacity returns to 100%; aria-disabled and aria-busy are no longer set on group or buttons |

