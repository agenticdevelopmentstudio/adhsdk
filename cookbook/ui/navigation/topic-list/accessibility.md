
- **Role/trait**: Not explicitly set via a custom accessibility role
  anywhere in this component; the list, its rows, and its cells use the
  platform's default roles, with group header rows marked as group rows.
- **Label requirements**: Each item row's label carries an explicit
  accessibility identifier (a slugified form of the item's title,
  prefixed for this component - see **item-accessibility-id-from-title**),
  and its accessible name is its own displayed text (the item's title) -
  no separate accessibility-label override is set. A group header's
  label carries the identifier its section supplies (see
  **section-accessibility-id**), set on every use of the pooled cell and
  cleared when the section supplies none; title and
  footer/accessory views carry no accessibility identifier in this
  component.
- **Announce state changes**: Not implemented. When the grouped setter
  reloads the list with a different row count, no accessibility change
  notification informs assistive technology that the visible row set
  changed; a screen-reader user hears nothing until navigating back into
  the list.
- **Keyboard and assistive-technology paths**: Arrow-key row navigation
  and keyboard selection are the list's platform defaults, gated by the
  same selection-gating check as a click; an item row's label answers an
  accessibility press by selecting its row. Drag and drop has no keyboard
  or assistive-technology alternative: the component adds no key command
  or accessibility action that moves a payload onto a row. The row
  context menu has no keyboard path of its own either: the component adds
  no key command or accessibility action for it, and because the menu is
  built for the list's clicked row, opening it with no clicked row yields
  an empty menu, which is not shown. The double-click callback likewise
  has no keyboard equivalent.
- **Minimum tap target**: The list uses its platform's default row-sizing
  style rather than a custom row height, so the row's actual height is
  derived from that default style rather than a literal value this
  component sets. Whatever value that resolves to for the fonts this
  component uses is well under the 44x44pt iOS minimum. This is expected
  for a pointer/keyboard-driven desktop list (not a touch surface); the
  44x44pt (iOS) / 48x48dp (Android) minimum applies to the touch-platform
  translations described in Platform Notes, not to this desktop control.
  Additionally, an item row label's accessibility press handler gives
  assistive technology a press path into a row regardless of its rendered
  size, since activation does not depend on a pointer hitting a physical
  target.

