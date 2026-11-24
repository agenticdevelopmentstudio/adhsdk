
- **Decision**: The component hardcodes exactly three selectable privacy levels (only-me, hub, public) plus a fourth disabled "Team / Org" affordance, rather than accepting a dynamic list of options.
  **Rationale**: Privacy levels are a fixed, app-wide configuration unlikely to change at runtime. The fixed set also bakes in app-specific vocabulary ("Hub members") and a product roadmap item ("Team / Org — Coming soon"), so an app that needs different wording, or a different level set, needs its own fork or a prop-driven variant of this ingredient rather than the ability to reconfigure this one in place.
  **Approved**: pending

- **Decision**: An unrecognized value coming off the wire is converted to `only-me` by the wire-to-level conversion utility (`PRIVACY_LEVEL_FROM_WIRE`; see the React/Web Platform Note), rather than passed through or defaulted to `public`.
  **Rationale**: A deliberate fail-closed choice — a backend value this build doesn't recognize (a pre-migration row, a replica mid-deploy) renders as the most restrictive level rather than risking data exposed as public.
  **Approved**: pending

- **Decision**: The component keeps an internal `cursor` (keyboard-navigation focus) distinct from `value` (the committed selection), and resets `cursor` to `value` every time the popover opens.
  **Rationale**: Lets the user navigate options without committing a change until Enter/Space or a click, while always starting keyboard navigation from the currently selected option.
  **Approved**: pending

- **Decision**: If `disabled` becomes `true` while the popover is already open, the popover is left open; closing it on that transition was not implemented.
  **Rationale**: This is the source's actual behavior. The component has no `open` prop, so a caller cannot close it from outside today; handling the disabled-while-open transition would need a change to the component.
  **Approved**: pending

- **Decision**: Hovered and keyboard-focused options share the same highlight style (`apt-highlight/15`).
  **Rationale**: Keeps a single visual rule instead of two, and communicates that both interaction modes have the same effect; a user cannot tell which one produced the highlight.
  **Approved**: pending

- **Decision**: The `move` function's null-cursor branch is unreachable dead code, not a real keyboard-navigation contract. If it ever ran with a `null` cursor it would seed index 0 and then apply the delta (`Math.min(navLevels.length - 1, Math.max(0, idx + delta))`), sending ArrowDown to `hub` and ArrowUp to `only-me`, not both to `only-me`.
  **Rationale**: `cursor` is always `value` (never `null`) by the time the listbox surface can receive a keydown: opening sets `cursor` to `value` in the same synchronous update that sets `open` to `true` (see **reset-cursor-to-value-on-open**), and the Popover this component composes removes its content from the DOM when closed (the hide-on-close-unmount requirement of [adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)), so no closed-popover state lets a keyboard user press an arrow key with `cursor` still `null`. The branch is left in place as a defensive fallback rather than removed.
  **Approved**: pending

- **Decision**: The popover panel has a fixed width of 288px (`w-72`) that does not respond to the trigger's width or the viewport.
  **Rationale**: Keeps the option descriptions wrapping consistently regardless of where the component is placed on the page.
  **Approved**: pending

- **Decision**: The options render as a custom ARIA `listbox` rather than a native `<select>`.
  **Rationale**: Each option is a rich row — an icon, a label, and a description line, plus a disabled "coming soon" row with a badge — that a native `<select>`'s `<option>` elements cannot render, so the custom listbox is the minimum needed to meet the visual requirement.
  **Approved**: pending

- **Decision**: The listbox implements only part of the APG listbox keyboard pattern — Arrow Up/Down, Enter/Space, and Escape — and leaves out Home/End, letter typeahead, opening via ArrowUp on the trigger, and any custom Tab/blur handling.
  **Rationale**: This is the implemented scope; Tab and blur fall through to the browser's native focus handling, and Home/End/typeahead were not built. See the Accessibility section's Keyboard navigation note for the resulting gap.
  **Approved**: pending

