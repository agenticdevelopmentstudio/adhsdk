
- Release outside the button: a window `pointerup`/`pointercancel` listener
  (attached only while held) ends the hold, so the press never sticks after the
  pointer is released off the button. (MUST — T6.)
- Popup/menu triggers (`aria-haspopup`) deliberately skip the dip so opening a
  menu doesn't look like a press. (MUST — T8.)
- Keyboard activation never sets `data-pressed` — the pressed look is pointer-only. (MUST — T7.)
- A consumer's own pointer handler is composed, not replaced. (MUST — T5.)
- `disabled` buttons receive no pointer events (`pointer-events-none`), so they
  never enter the pressed state. (MUST.)
- No ancestor sets `--adh-button-min-height`/`--adh-button-min-width`: both
  default to `0px`, which imposes no floor beyond the size variant's own fixed
  `h-*`/`size-*` height/width — the button is exactly as large as its size
  variant, no larger. (MUST.)
- An icon-size button (`icon`/`icon-xs`/`icon-sm`/`icon-lg`) whose ancestor
  raises only `--adh-button-min-height`: `--adh-button-min-width` follows it
  automatically, so the button stays square without the ancestor also setting
  a width variable. (MUST — T15.)
- An SVG child that already carries an explicit `size-*` class: the
  `:not([class*='size-'])` selector excludes it from the default icon sizing
  rule, so the button MUST NOT override an explicitly sized icon.
- **Null and empty input**: `children` may be omitted or empty; the Base UI
  primitive MUST NOT throw and renders with no visible label (see
  Accessibility for the resulting accessible-name gap). `variant`/`size`
  omitted resolve to the `default`/`default` `cva` defaults (MUST — T13).
  `className` omitted is a no-op in the `cn()` merge.
- **Boundary values**: not applicable in the numeric sense — `variant` and
  `size` are fixed string enumerations, not numeric ranges. A value outside
  the `VariantProps<typeof buttonVariants>` union is a TypeScript compile-time
  error, not a runtime boundary condition.
- **Concurrent access**: not applicable — the button is a single, synchronously
  rendered DOM element with no state shared across sessions, tabs, or threads;
  the pressed-tracking state is local to one `PressableButton` instance.
- **Error states**: not applicable — the button has no network, database, or
  file-system dependency; it renders synchronously from its props.
- **Offline or disconnected state**: not applicable — the button performs no
  network operation of its own.

