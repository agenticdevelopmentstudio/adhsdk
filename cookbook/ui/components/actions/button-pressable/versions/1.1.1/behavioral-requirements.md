
Requirements below are phrased over an **active press** — the interval from a
`pointerdown` on the rendered primitive to the earliest of an element-level or
window-level `pointerup`/`pointercancel` — rather than over the internal
`held` state variable. See Design Decisions for why.

- **render-as-forwarded-primitive**: PressableButton MUST render the underlying Base UI `Button` primitive with every prop other than the five intercepted pointer handlers (`onPointerDown`, `onPointerUp`, `onPointerLeave`, `onPointerEnter`, `onPointerCancel`) passed through unchanged.
- **data-slot**: PressableButton MUST set `data-slot="button"` on the rendered primitive.
- **pressed-absent-by-default**: PressableButton MUST leave the `data-pressed` attribute unset on the rendered primitive before any pointer interaction.
- **pressed-on-pointerdown**: PressableButton MUST set `data-pressed=""` on the rendered primitive when a `pointerdown` event is dispatched on it, beginning an active press.
- **pressed-cleared-on-element-pointerup**: PressableButton MUST remove the `data-pressed` attribute when a `pointerup` event is dispatched on the rendered primitive, ending the active press.
- **pressed-cleared-on-pointerleave-during-active-press**: PressableButton MUST remove the `data-pressed` attribute when a `pointerleave` event is dispatched on the rendered primitive during an active press.
- **pressed-restored-on-pointerenter-during-active-press**: PressableButton MUST set `data-pressed=""` again on the rendered primitive when a `pointerenter` event is dispatched on it during an active press.
- **pressed-unaffected-by-pointerenter-outside-active-press**: PressableButton MUST NOT change the `data-pressed` attribute when a `pointerenter` event is dispatched on the rendered primitive outside an active press.
- **pressed-cleared-on-element-pointercancel**: PressableButton MUST remove the `data-pressed` attribute when a `pointercancel` event is dispatched on the rendered primitive, ending the active press.
- **pressed-cleared-on-window-release-during-active-press**: PressableButton MUST remove the `data-pressed` attribute when a `pointerup` or `pointercancel` event is dispatched anywhere on `window` during an active press, regardless of the event's target.
- **window-release-no-effect-outside-active-press**: PressableButton MUST NOT change the `data-pressed` attribute, and MUST NOT throw, in response to a `pointerup` or `pointercancel` event dispatched on `window` outside an active press.
- **forwarded-handler-invoked-when-provided**: PressableButton MUST invoke a caller-supplied `onPointerDown`, `onPointerUp`, `onPointerLeave`, `onPointerEnter`, or `onPointerCancel` prop, when one is provided, every time the corresponding pointer event fires on the rendered primitive.
- **pressed-unaffected-by-keyboard-activation**: PressableButton MUST NOT change the `data-pressed` attribute in response to keyboard activation (Space or Enter).
- **no-pointer-capture**: PressableButton MUST NOT call `setPointerCapture` on any pointer event it handles.

