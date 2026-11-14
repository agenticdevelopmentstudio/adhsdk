
- The component is not a control and exposes no role. The menu item it serves
  carries the role, title and shortcut; those belong to whoever builds the
  item.
- The checked mark set through the item's state is a native menu item state,
  so assistive technology reads it as the item's checked value.
- The enabled value returned on validation is the native enabled state that
  assistive technology reads from the item.
- Minimum target size: Not applicable: the component is not a hit target; the
  menu system sizes menu rows.
- Keyboard: the component adds no key handling; the item's key equivalent is
  owned by the item that points at it.

