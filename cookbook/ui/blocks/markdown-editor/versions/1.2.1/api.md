
`@adh-sdk/ui/blocks/markdown-editor`:

```ts
interface MarkdownEditorProps {
  value: string
  onChange: (next: string) => void
  label?: React.ReactNode        // default "Markdown body"
  placeholder?: string
  rows?: number                  // default 16; ignored when `fill`
  spellCheck?: boolean           // default false
  onUpload?: (text: string, fileName: string) => void
  quickReference?: boolean       // default true
  toolbarExtras?: React.ReactNode
  toolbarLabel?: string          // default "Markdown editor toolbar"
  className?: string
  textareaClassName?: string
  disabled?: boolean
  fill?: boolean                 // default false — root becomes `min-h-0 flex-1`
                                  // and the textarea flexes to the parent's
                                  // height instead of a fixed `rows` box; the
                                  // parent MUST supply a bounded height
}
export function MarkdownEditor(props: MarkdownEditorProps): React.ReactElement
```

