
**Semantic CSS class names**
**Decision**: All components apply stable `adh-dropdown-menu__*` class names to the DOM to provide a public theming surface.
**Rationale**: This design enables theme editors and user CSS overrides to target dropdown menu elements without relying on implementation details. The class names are committed to backward compatibility.
**Approved**: pending

**closeOnClick default flips for checkbox, radio, and link items**
**Decision**: This wrapper inverts Base UI's `closeOnClick` default from `false` to `true` for `CheckboxItem`, `RadioItem`, and `LinkItem`.
**Rationale**: Base UI's `CheckboxItem` and `RadioItem` default `closeOnClick` to `false` to keep the menu open while toggling state, but this wrapper matches typical dropdown menu behavior where selecting an option closes the menu. `LinkItem` is defaulted to `true` for the same reason: in this codebase, `render={<Link/>}` navigates client-side without unmounting the header, so the menu would remain open after navigation unless explicitly closed. This decision is traced to Base UI's `Menu` documentation and to the code comments on the `DropdownMenuLinkItem` and `DropdownMenuCheckboxItem` wrapper functions.
**Approved**: pending

**Submenu positioning defaults**
**Decision**: `DropdownMenuSubContent` does not set its own positioning defaults.
**Rationale**: Base UI's Positioner already defaults to `side="inline-end"` (right in LTR) and `align="start"` (top), which produces the classic submenu flyout behavior; explicit positioning overrides remain available via props.
**Approved**: pending

**SubmenuTrigger includes ChevronRight icon**
**Decision**: The ChevronRight icon is always rendered on `SubmenuTrigger` as a visual indicator that the item opens a submenu; it is not conditionally renderable.
**Rationale**: Consuming code cannot hide it, keeping the submenu affordance consistent everywhere the component is used.
**Approved**: pending

**Label component not bound to Group**
**Decision**: `DropdownMenuLabel` is a plain styled `<div>`, not Base UI's `MenuPrimitive.GroupLabel`.
**Rationale**: `MenuPrimitive.GroupLabel` throws when rendered outside a `Menu.Group`, and this label is also used standalone (e.g. as a heading in the DebugMenu). This flexibility comes at the cost of no built-in ARIA relationship to a group.
**Approved**: pending

**Reference implementation**
**Decision**: The `@adh-sdk/ui` package's dropdown-menu component — `DropdownMenu`, `DropdownMenuContent`, `DropdownMenuItem`, `DropdownMenuLinkItem`, `DropdownMenuCheckboxItem`, `DropdownMenuRadioItem`, and related exports, built on Base UI's `Menu` primitive — is the reference implementation for this ingredient's behavioral contract.
**Rationale**: Citing the package and exported symbol names, rather than a file path or line numbers, keeps the reference stable as the file is refactored. See the Base UI `Menu` documentation in references.
**Approved**: pending

**Long item text truncates**
**Decision**: Item text that exceeds the available menu width truncates with an ellipsis rather than wrapping.
**Rationale**: Keeps the menu's width and item height consistent; wrapping would enlarge item height unpredictably and complicate keyboard-navigation focus rings.
**Approved**: pending

