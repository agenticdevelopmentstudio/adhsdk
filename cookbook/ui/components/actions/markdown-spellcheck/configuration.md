
`@adh-sdk/ui/components/markdown-spellcheck`

| Option | Type | Default | Description |
|---|---|---|---|
| `value` | `string` | — (required) | The markdown source to check |
| `onApply` | `(next: string) => void` | — (required) | Called with the next source when a suggestion is applied |
| `label` | `ReactNode` | `"Check spelling"` | Visible text / accessible name of the toggle |
| `debounceMs` | `number` | `600` | Debounce before re-linting after the source settles |
| `createLinter` | `CreateMarkdownLinter` | `createHarperLinter` | Linter factory (DI seam); inject a fake in tests |
| `disabled` | `boolean` | `false` | Disable the toggle |
| `className` | `string` | — | Extra classes on the toggle button |

```ts
export interface SpellIssue {
  start: number
  end: number
  flagged: string
  message: string
  suggestions: string[]
}

export interface MarkdownLinter {
  lint(source: string): Promise<SpellIssue[]>
  apply(source: string, issueIndex: number, suggestionIndex: number): Promise<string>
  dispose(): void
}

export type CreateMarkdownLinter = () => MarkdownLinter | Promise<MarkdownLinter>

export const createHarperLinter: CreateMarkdownLinter

export function MarkdownSpellCheck(props: {
  value: string
  onApply: (next: string) => void
  label?: React.ReactNode
  debounceMs?: number
  createLinter?: CreateMarkdownLinter
  disabled?: boolean
  className?: string
}): React.JSX.Element
```

The default `createHarperLinter` dynamically imports `harper.js` +
`harper.js/binary`, constructs a `WorkerLinter` (American dialect), and lints with
`{ language: 'markdown', dedup: true }`. The exported types never reference
harper, so consumers do not need harper resolvable to type-check.

