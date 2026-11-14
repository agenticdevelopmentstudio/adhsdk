
- **Role**: Button (implicit from `<button>` element)
- **Label requirement**: `aria-label` MUST communicate the current mode and the next mode in the cycle. Before hydration (SSR and the client's first render) it is the placeholder `"Theme"`. After the component mounts it becomes `Theme: {mode}. Click to switch to {next}.` for `light`/`dark`, or `Theme: Auto (currently {resolved}). Click to switch to dark.` for `auto` (the next mode from `auto` is always `dark`), where `{resolved}` is `light` or `dark` from the system preference.
- **Title**: Tooltip text MUST be `undefined` until the component mounts, then read `Following system ({resolved})` for `auto` mode, or `Light mode — click for auto` / `Dark mode — click for light` for explicit modes.
- **Touch target size**: The component itself is an icon button and relies on the host's button styling to meet platform touch target minimums (44×44pt on iOS, 48×48dp on Android, platform-appropriate for web).
- **Keyboard navigation**: Button MUST be keyboard accessible and focusable (inherent from `<button>` element).
- **Announcement of state**: The accessible name (`aria-label`) MUST update synchronously with `mode` — in the same render — so assistive technology reads the current value whenever it next queries the element. The component places no requirement on how or when a screen reader announces the change; that is outside its control.
- **No color-only information**: The three different icons (Sun, Moon, RefreshCw) serve as distinct visual indicators, not relying on color alone.

