
- **open-visible** (full-featured, lightweight): The component MUST render visible when the `open` prop is `true`.
- **hide-on-close-unmount** (full-featured): When `open` is `false`, `PopoverContent` MUST be removed from the DOM. `PopoverContent` does not forward a `keepMounted` prop to Base UI's `Popover.Portal`, so this uses Base UI's default (`keepMounted={false}`) and cannot be overridden through this wrapper.
- **hide-on-close-visibility** (lightweight): When `open` is `false`, the panel MUST remain mounted and be hidden via the `hover-popover--open` class rather than being removed from the DOM, so its content is present in server-rendered HTML for non-JavaScript clients.
- **placement** (full-featured, lightweight): The component MUST accept a placement prop naming which side of the anchor the panel appears on: `side` on `PopoverContent` (`'top' | 'bottom' | 'left' | 'right'`, default `'bottom'`), or `placement` on the lightweight `Popover` (`'top' | 'bottom'` only, default `'top'`).
- **render-children** (full-featured, lightweight): The component MUST render all provided child content within the panel.
- **side-offset** (full-featured): `PopoverContent` MUST accept a `sideOffset` prop to control the gap, in pixels, between the panel and the trigger element (default `8`). The lightweight variant has no equivalent prop; its gap is a CSS custom property on `.hover-popover`.
- **alignment** (full-featured): `PopoverContent` MUST accept an `align` prop to control alignment along the axis perpendicular to `side` (`'start' | 'center' | 'end'`, default `'center'`). The lightweight variant has no equivalent prop.
- **custom-styling** (full-featured, lightweight): The component MUST accept a `className` prop, concatenated after its own default classes, to allow custom styling.
- **arrow** (full-featured): `PopoverContent` MAY render an optional pointer indicator, controlled by the `arrow` prop (default `false`). The lightweight variant always renders its arrow as a fixed part of the panel; it has no prop to disable it.

