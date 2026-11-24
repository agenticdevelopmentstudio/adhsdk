| Prop | Type | Default | Slot |
|---|---|---|---|
| `title` | `React.ReactNode` | required | Primary text in the toggle, truncated |
| `subtitle` | `React.ReactNode` | none | Secondary muted text under the title, truncated |
| `actions` | `React.ReactNode` | none | Trailing header controls, outside the toggle |
| `defaultOpen` | `boolean` | `false` | Initial state in uncontrolled mode |
| `open` | `boolean` | none | Controlled open state; when provided, the component never writes its own |
| `onOpenChange` | `(open: boolean) => void` | none | Called with the next value on every toggle |
| `className` | `string` | none | Extra classes on the container |
| `headerClassName` | `string` | none | Extra classes on the header row |
| `children` | `React.ReactNode` | required | Body, mounted only when open |

Export: `Disclosure`.
