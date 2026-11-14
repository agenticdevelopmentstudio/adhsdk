
- **runs-action-on-selection**: When the menu system sends the perform
  message, the component MUST call the action closure exactly once.
- **ignores-sender**: The component MUST NOT read or use the sender passed
  with the perform message; the sender MAY be absent.
- **action-selector-name**: The perform message MUST be exposed to the menu
  system under the selector name `performMenuAction:`.
- **enabled-from-closure**: When the menu system validates an item, the
  component MUST return the result of the enabled closure.
- **enabled-default-true**: When no enabled closure is supplied, the
  component MUST report every validated item as enabled.
- **enabled-evaluated-each-validation**: The component MUST call the enabled
  closure on every validation and MUST NOT cache its result.
- **checked-sets-state**: When a checked closure is supplied, validation MUST
  set the item's state to on if the closure returns true and to off if it
  returns false.
- **checked-absent-leaves-state**: When no checked closure is supplied,
  validation MUST NOT change the item's state.
- **checked-independent-of-enabled**: Validation MUST apply the checked state
  to the item whether the enabled closure returns true or false.
- **main-actor-only**: The component MUST be used only from the main actor;
  its closures run on the main actor.
- **no-retention-of-item**: The component MUST NOT hold a reference to the
  menu item it validates or serves.
- **host-retains-target**: The host SHOULD keep a strong reference to each
  target for as long as its menu item exists, because the menu item holds its
  target weakly.
- **no-error-path**: The component MUST NOT catch, log or report anything
  from its closures; a closure that fails does so in the caller's context.

