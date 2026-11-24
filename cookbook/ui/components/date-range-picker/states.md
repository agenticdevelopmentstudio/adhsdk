
| State | Appearance change |
|-------|------------------|
| Default | Two fields showing `value.from` and `value.to`. |
| Focused | Not styled by this component; the shared Input component and the browser's native control own the focus indication. |
| Pressed | Not applicable: the component has no pressable element of its own; the native date control owns its calendar button. |
| Disabled | Not applicable: `DateRangePickerProps` has no `disabled` prop and the component forwards nothing to the fields. |
| Loading | Not applicable: the component renders synchronously from `value` and never waits on anything. |
| Out of range | No change. The component shows no error for a typed date outside `min`, `max` or the other end; the browser's constraint-validation state, if any, is the only signal. |

