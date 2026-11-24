
- **required-label**: The component MUST accept a `label` prop (string) that describes what the menu acts on, as a screen reader announces it (e.g., "Registry actions"). TypeScript enforces that the prop is provided; the component does not validate that the value is non-empty — the host guarantees a meaningful, non-empty label.
- **gear-icon**: The component MUST render a settings gear glyph at 14 units (pixels or points) in size.
- **dropdown-trigger**: The component MUST render as a `DropdownMenuTrigger`, and MUST be composed as a child of a host-provided `DropdownMenu` — the host supplies the `DropdownMenuContent` that the trigger opens.
- **disabled-state**: The component MUST accept a `disabled` prop (boolean, defaults to `false`) that disables user interaction.
- **disabled-opacity**: When `disabled` is `true`, the component MUST apply 40% opacity to the trigger.
- **icon-aria-hidden**: The component MUST render the settings icon with `aria-hidden` set to `true` so the icon does not announce redundantly.
- **aria-label**: The component MUST set the `aria-label` attribute of the trigger to the value of the `label` prop.
- **class-override**: The component MUST accept an optional `className` prop that allows callers to override or extend the default styling.
- **focus-indicator**: The component MUST suppress the platform's default focus outline and rely solely on a 2-unit focus ring in the accent token at 40% opacity, shown on keyboard focus only, as the visible focus indicator.
- **hover-color**: On hover, the component MUST change its foreground color from the dim-text token to the normal-text token.

