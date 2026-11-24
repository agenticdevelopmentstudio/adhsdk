
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| button-pressable-001 | render-as-forwarded-primitive | Render with `variant="secondary"` and `aria-label="Save"` | Rendered element receives `variant="secondary"` and `aria-label="Save"` unchanged |
| button-pressable-002 | data-slot | Render with any props | Rendered element has `data-slot="button"` |
| button-pressable-003 | pressed-absent-by-default | Initial render, no interaction | Rendered element has no `data-pressed` attribute |
| button-pressable-004 | pressed-on-pointerdown | `pointerdown` dispatched on the element | Rendered element has `data-pressed=""` immediately after the event |
| button-pressable-005 | pressed-cleared-on-element-pointerup | `pointerdown` then `pointerup`, both on the element | `data-pressed` absent after `pointerup` |
| button-pressable-006 | pressed-cleared-on-pointerleave-during-active-press | `pointerdown` then `pointerleave`, both on the element | `data-pressed` absent after `pointerleave` |
| button-pressable-007 | pressed-restored-on-pointerenter-during-active-press | `pointerdown`, `pointerleave`, `pointerenter`, all on the element | `data-pressed=""` present again after `pointerenter` |
| button-pressable-008 | pressed-unaffected-by-pointerenter-outside-active-press | `pointerenter` on the element with no prior `pointerdown` | `data-pressed` remains absent after `pointerenter` |
| button-pressable-009 | pressed-cleared-on-element-pointercancel | `pointerdown` then `pointercancel`, both on the element | `data-pressed` absent after `pointercancel` |
| button-pressable-010 | pressed-cleared-on-window-release-during-active-press | `pointerdown` on the element, then `pointerup` dispatched on `window` (not on the element) | `data-pressed` absent after the window `pointerup` |
| button-pressable-011 | pressed-cleared-on-window-release-during-active-press | `pointerdown` on the element, then `pointercancel` dispatched on `window` (not on the element) | `data-pressed` absent after the window `pointercancel` |
| button-pressable-012 | pressed-cleared-on-window-release-during-active-press | `pointerdown` on the element, then `pointerleave` on the element (no `pointerup`), then `pointerup` on `window` | `data-pressed` absent after the window `pointerup`, proving the active press begun by `pointerdown` survived the intervening `pointerleave` |
| button-pressable-013 | window-release-no-effect-outside-active-press | `pointerup` dispatched on `window` with no prior `pointerdown` on the element | No change to `data-pressed` and no error is thrown |
| button-pressable-014 | window-release-no-effect-outside-active-press | `pointerdown` then `pointerup`, both on the element, then a second `pointerup` dispatched on `window` | The second window `pointerup` produces no additional change to `data-pressed` |
| button-pressable-015 | forwarded-handler-invoked-when-provided | Render with an `onPointerDown` spy prop, dispatch `pointerdown` on the element | Spy is called exactly once |
| button-pressable-016 | pressed-unaffected-by-keyboard-activation | Focus the element, press `Enter` (and separately, `Space`), with no pointer event | `data-pressed` remains absent throughout and after activation |
| button-pressable-017 | no-pointer-capture | Spy on `setPointerCapture` before rendering, then dispatch `pointerdown` on the element | The `setPointerCapture` spy is never called |
| button-pressable-018 | pressed-on-pointerdown | `pointerdown` dispatched on the element with no `onPointerDown` prop supplied | No error is thrown; `data-pressed=""` is still set |
| button-pressable-019 | pressed-on-pointerdown | `pointerdown` dispatched twice on the element with no intervening release | `data-pressed=""` remains set after the second `pointerdown`; no error is thrown |
| button-pressable-020 | window-release-no-effect-outside-active-press | `pointerdown` then `pointerup`, both on the element (ending the active press), then `pointercancel` dispatched on the element | `data-pressed` remains absent; no error is thrown |
| button-pressable-021 | pressed-cleared-on-window-release-during-active-press | `pointerdown` with `pointerId` 1 on the element, then `pointerdown` with `pointerId` 2 on the element (no intervening release), then `pointerup` with `pointerId` 1 dispatched on `window` | `data-pressed` is cleared — the window listener ends the active press regardless of which `pointerId` released |
| button-pressable-022 | pressed-unaffected-by-pointerenter-outside-active-press | `pointerdown` then `pointerup` on the element (completing a press), then `pointerenter` on the element | `data-pressed` remains absent after the later `pointerenter`, since the active press already ended |

