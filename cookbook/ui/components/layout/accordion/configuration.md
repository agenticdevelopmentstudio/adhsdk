
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `className` (all components) | `string` | `undefined` | Additional CSS classes merged with defaults via the `cn()` utility; allows customization of appearance and layout |
| `children` (all components) | `ReactNode` | `undefined` | Content rendered inside: trigger text for AccordionTrigger, panel content for AccordionPanel |
| `...props` (`Accordion`) | `React.ComponentProps<typeof AccordionPrimitive.Root>` | — | Root-level props forwarded to the primitive, e.g. `multiple`, `value`, `defaultValue`, `onValueChange`, `disabled` |
| `...props` (`AccordionItem`) | `React.ComponentProps<typeof AccordionPrimitive.Item>` | — | Item-level props forwarded to the primitive, e.g. `value`, `disabled` |
| `...props` (`AccordionTrigger`) | `React.ComponentProps<typeof AccordionPrimitive.Trigger>` | — | Trigger-level props forwarded to the primitive |
| `...props` (`AccordionPanel`) | `React.ComponentProps<typeof AccordionPrimitive.Panel>` | — | Panel-level props forwarded to the primitive |

