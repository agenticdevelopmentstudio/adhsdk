
`@adh-sdk/ui/components/markdown-quick-reference`

| Option | Type | Default | Description |
|---|---|---|---|
| `side` | `PopoverContentProps["side"]` | `"bottom"` | Popover placement side |
| `align` | `PopoverContentProps["align"]` | `"end"` | Popover alignment along the side |
| `triggerLabel` | `ReactNode` | `"Markdown"` | Visible text on the trigger button |
| `className` | `string` | — | Extra classes on the trigger button |

```ts
type PopoverContentProps = React.ComponentProps<typeof PopoverContent>

export function MarkdownQuickReference(props: {
  side?: PopoverContentProps["side"]
  align?: PopoverContentProps["align"]
  triggerLabel?: React.ReactNode
  className?: string
}): React.ReactElement
```

