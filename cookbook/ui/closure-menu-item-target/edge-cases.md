
- **Null or empty input**: the perform message accepts an absent sender and
  runs the action anyway (MUST). The action closure is required by the
  initializer; the enabled closure defaults to always true and the checked
  closure defaults to absent, and when it is absent the item's state is left
  alone (MUST).
- **Boundary values**: Not applicable: the component takes no numeric input.
- **Concurrent access**: the component is isolated to the main actor, so the
  compiler stops calls from other threads (MUST). The closures are called
  serially on the main thread.
- **Error states**: the component has no error path. A closure that crashes
  crashes the caller; the component does not guard it (MUST NOT catch).
- **Offline or disconnected state**: Not applicable: the component does no
  network or storage work.
- **Item that is disabled**: when the enabled closure returns false the menu
  system does not send the perform message, so the action does not run
  (SHOULD hold for any host that honours validation). Validation still sets the
  checked state first.
- **Released target**: a menu item does not retain its target, so a host that
  drops the target leaves an item that does nothing when chosen (the host
  SHOULD retain it).
- **Reused item**: the component keeps no reference to items, so one target
  validates any item it is asked about; each validation overwrites the state
  when a checked closure exists.

