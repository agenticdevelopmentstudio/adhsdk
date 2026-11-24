
No test beside the source exercises the component directly; the vectors below
follow the closure contract in the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| closure-menu-item-target-001 | runs-action-on-selection | Action closure increments a counter; send perform with a menu item as sender | Counter is 1 |
| closure-menu-item-target-002 | ignores-sender | Send perform with no sender | Action closure runs once; no failure |
| closure-menu-item-target-003 | enabled-default-true | Target built with only an action; validate an item | Returns true |
| closure-menu-item-target-004 | enabled-from-closure | Enabled closure returns false; validate an item | Returns false |
| closure-menu-item-target-005 | enabled-evaluated-each-validation | Enabled closure reads a flag; validate, flip the flag, validate again | Returns the flag value each time (true then false) |
| closure-menu-item-target-006 | checked-sets-state | Checked closure returns true; validate an item whose state is off | Item state is on |
| closure-menu-item-target-007 | checked-sets-state | Checked closure returns false; validate an item whose state is on | Item state is off |
| closure-menu-item-target-008 | checked-absent-leaves-state | No checked closure; validate an item whose state is on | Item state stays on |
| closure-menu-item-target-009 | checked-independent-of-enabled | Enabled returns false, checked returns true; validate an item | Returns false and item state is on |
| closure-menu-item-target-010 | action-selector-name | Item action is the selector named `performMenuAction:` with this target | Selecting the item runs the action closure |
| closure-menu-item-target-011 | host-retains-target | Item target is the only reference to a target that nothing else retains | Target is released and selecting the item does nothing; host MUST retain it |
| closure-menu-item-target-012 | no-error-path, main-actor-only, no-retention-of-item | Validate and perform from the main actor with closures that complete normally | No log output, no stored item reference, calls complete on the main actor |

