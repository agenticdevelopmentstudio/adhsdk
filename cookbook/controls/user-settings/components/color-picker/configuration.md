
| Prop | Type | Required | Description |
|------|------|----------|-------------|
| `value` | `string` | yes | Hex color, for example `#ff0000`. |
| `onChange` | `(hex: string) => void` | yes | Called with the new lowercase `#rrggbb` string. |
| `label` | `ReactNode` | no | Label associated with the input. |
| `hint` | `ReactNode` | no | Hint text below the field. |
| `disabled` | `boolean` | no | Disables the input. |
| `id` | `string` | no | Id for the input; generated when omitted. |
| `className` | `string` | no | Extra class on the field container. |

The component takes no configuration beyond these props.
