
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | ReactNode | undefined | Optional label text or element displayed above the slider. |
| `hint` | ReactNode | undefined | Optional hint text or element displayed below the slider. |
| `value` | string \| number | (required) | The currently selected choice value. SHOULD match one of the choice values; if no match is found, the component falls back to the first choice rather than erroring (see **maintain-value-in-range**). |
| `onChange` | function | (required) | Callback invoked with the selected choice's value when the slider moves. |
| `choices` | `Choice<T>[]` | (required) | Array of selectable options. Each choice has a `value` and `label`. |
| `disabled` | boolean | false | When true, slider interaction is disabled. |
| `className` | string | undefined | Optional additional CSS class(es) to apply to the root container. |
| `id` | string | (auto-generated) | Optional custom ID for the range input. If omitted, a unique ID is generated via `useId()`. |

