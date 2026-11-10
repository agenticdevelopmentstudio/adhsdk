
`@adh-sdk/ui/blocks/editor-section`:

```ts
interface EditorSectionItem {
  id: string
  label: string
  sublabel?: string
  icon?: React.ReactNode      // 16px leading icon (rail fills a neutral ring if omitted)
  warn?: boolean              // shows a ⚠ at the row's right edge
  warnTitle?: string
  warnCount?: number          // when set (and warn), renders a "⚠ N" count badge
}
interface EditorSectionProps {
  title: React.ReactNode
  titleBadge?: React.ReactNode
  createLabel: string
  items: EditorSectionItem[]
  selectedId: string | null
  onSelect: (id: string) => void
  onNew: () => void
  onDelete?: () => void        // omit → no Delete button
  onCancel: () => void
  onSave: () => void
  dirty: boolean
  busy?: boolean               // default false
  canDelete?: boolean          // default: "anything selected"
  error?: React.ReactNode      // red line under the toolbar
  emptyList?: React.ReactNode  // rail empty label; default "Nothing here yet."
  emptyDetail: React.ReactNode // EmptyState title when nothing selected
  listHeader?: React.ReactNode // rail leading slot; hidden while collapsed
  railWidth?: number           // widen for long-identifier rails
  children: React.ReactNode    // the record editor form, shown while editing
  className?: string
}
export function EditorSection(props: EditorSectionProps): React.ReactElement
```

Accessibility: the toolbar is `role="toolbar"` (via `ButtonBar`) with labeled
buttons whose `disabled` reflects the editing/dirty/busy state; each warn badge
carries `warnTitle` as its title/aria-label; the rail's selection and collapse
behaviors come from `TopicDetail`.

