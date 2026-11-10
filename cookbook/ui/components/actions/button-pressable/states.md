
| State | Appearance change |
|-------|------------------|
| Default | `data-pressed` absent; no active press in progress |
| Pressed | `data-pressed=""` present; entered on `pointerdown`, held through `pointerleave`/`pointerenter` cycles while the active press continues |
| Held, Not Pressed | `data-pressed` absent while the active press continues (a later window-level release still ends it) — entered when `pointerleave` fires during an active press, exited by `pointerenter` (returns to Pressed) or by any release (ends the active press, returns to Default) |
| Disabled | Not applicable: PressableButton contains no `disabled` logic; disabling is a concern of the primitive/CSS layer. |
| Focused | Not applicable: PressableButton contains no focus handling; focus state is managed by the Base UI Button primitive. |
| Loading | Not applicable: PressableButton contains no loading-state logic. |

The "Pressed" and "Held, Not Pressed" rows above cover two nested transitions
traceable to the source: while an active press is in progress, a
`pointerleave` clears `data-pressed` (the visual returns to Default while the
press stays active) and a subsequent `pointerenter` restores it, without ever
ending the active press. (Implementation: `button-pressable.tsx` tracks this
with internal `held`/`pressed` `useState` values; see Design Decisions.)

