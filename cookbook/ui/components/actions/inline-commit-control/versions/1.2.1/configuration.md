
`InlineCommitControl` props:

| Prop | Type | Meaning |
|---|---|---|
| `dirty` | `boolean` | Uncommitted edits exist — show the pair |
| `deleting` | `boolean?` | Delete armed — ✓ ✕ + red trash |
| `deletable` | `boolean?` | Offer the hover trash when clean |
| `busy` | `boolean?` | Commit in flight — soft-disable (`aria-disabled`, focus kept) + spinner |
| `onCommit` | `() => void` | Save edits / commit the armed delete |
| `onCancel` | `() => void` | Discard edits / disarm the delete |
| `onDelete` | `(() => void)?` | Arm (idle trash) or disarm (armed trash) |
| `subject` | `string?` | Accessible subject for button labels |

`InlineEditableText`: `value`, `onChange(value)`, optional
`onCommitEdit`/`onCancelEdit`, optional `variant` (`"default" | "mono" |
"muted"`), required `aria-label`, plus native input props.

`UnsavedChangesGuard`: `when` (guard active) and optional `onNavigate(href)`
(defaults to a full `location.assign`; pass the router's `push` to keep the
navigation client-side). The confirm copy is fixed ("Discard unsaved
changes?" / "Discard" / "Stay") — the guard is the platform's single
unsaved-changes prompt, not a per-page message.

`useInlineDrafts<Id, Draft>(describeError)` returns per-row helpers:
`draftOf(id, base)`, `isDirty(id, base)`, `changesOf(id, base)`, `edit(id,
patch)`, `clear(id)`, `isArmed(id)`, `toggleArmed(id)`, `isBusy(id)`,
`errorOf(id)`, `errors`, `runCommit(id, fn)`, and `settle(id, committed)`.

