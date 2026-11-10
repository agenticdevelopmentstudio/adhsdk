
- **render-button**: Component MUST render as a `<button>` element with `type="button"`.
- **render-three-icons**: Component MUST render three SVG icons (Sun, Moon, and RefreshCw refresh) simultaneously, with CSS controlling visibility based on mode.
- **accept-mode-prop**: Component MUST accept a `mode` prop with value "auto", "dark", or "light".
- **accept-on-change-callback**: Component MUST accept an `onChange` callback prop that receives the next mode in the cycle when the button is pressed.
- **cycle-modes**: Component MUST cycle modes in order: auto → dark → light → auto when clicked.
- **support-class-name**: Component MUST accept an optional `className` prop to apply custom styling (e.g., host button identity).
- **read-system-dark-preference**: When `mode` is "auto", component MUST query `window.matchMedia("(prefers-color-scheme: dark)")` to determine the effective mode.
- **listen-to-system-changes**: Component MUST subscribe to changes in the system dark mode preference and update the displayed effective mode without requiring props to change.
- **provide-aria-label**: Component MUST set an `aria-label` attribute that includes the current mode and the next mode in cycle, provided after client hydration.
- **provide-title-attribute**: Component MUST set a `title` attribute (tooltip) that describes the current mode and how to switch, provided after client hydration.
- **defer-label-until-mounted**: Component MUST NOT populate the real `aria-label`/`title` text on server-side rendering. `aria-label` MUST render the placeholder `"Theme"` during SSR and the client's first render; `title` MUST be omitted (`undefined`) until the component mounts. Both populate with their full text on the next render after mount.
- **handle-missing-match-media**: When `window.matchMedia` is unavailable (server-side rendering or older browsers), component MUST treat system dark mode as false.
- **host-html-attribute-sync**: The host application MUST keep `data-color-mode` (`"auto"` | `"dark"` | `"light"`) and the `dark` class on `<html>` synchronized with `mode` and the resolved effective mode. The component's own CSS (`.adh-color-mode-toggle__*`) reads only those host-controlled attributes to decide which icon and the auto-mode badge are visible — it does not read the `mode` prop for that purpose.

