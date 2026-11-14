
The shared `ToggleGroup` in `@adh-sdk/ui` — a segmented control, i.e. a row of
mutually-exclusive option buttons (e.g. a light/dark/system theme switcher, or a
left/center/right alignment picker). It is built on Base UI's `ToggleGroup` +
`Toggle` primitives so it stays consistent with the family's other base-ui
primitives (radio/switch), and it is themed entirely from `apt-*` tokens: the group
sits on the shared field shell and the pressed item takes a gold fill.

Two exports ship from `@adh-sdk/ui/components/toggle-group`:

- `ToggleGroup` — the container. It renders the Base UI `ToggleGroup` on the
  `fieldShellClass` (border + `apt-bg`) as an `inline-flex w-fit` row with `gap-1 p-1`.
- `ToggleGroupItem` — one option button. It renders the Base UI `Toggle`, styled as an
  `h-8` pill that shows muted text at rest, brightens on hover, takes a
  `focus-visible` gold ring, and — when pressed (`data-[pressed]`) — fills gold with
  `apt-bg` text.

Base UI's value model is always `string[]`. For a **single-select** control (the
common segmented-control case) leave `multiple` at its default (false) and pass
`value={[selected]}`; in `onValueChange` read `next[0]` and ignore the empty array
(clicking the already-pressed item would otherwise deselect it — a segmented control
always keeps one selection). Both props forward straight through to the Base UI
primitive, so multi-select and uncontrolled use are available by setting `multiple`
and/or `defaultValue`.

