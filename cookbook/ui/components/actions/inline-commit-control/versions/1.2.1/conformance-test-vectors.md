
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | hide-when-clean | `dirty=false`, `deletable=false` | Renders nothing |
| T2 | arm-delete | `dirty=false`, `deletable`, click trash | `onDelete` fired once; nothing deleted |
| T2b | reveal-trash-on-hover | `dirty=false`, `deletable`, hover the enclosing `inlineCommitHoverScopeClass` scope | Trash button `opacity-100`, `pointer-events-auto` |
| T2c | reveal-trash-on-hover | `dirty=false`, `deletable`, trash receives keyboard focus (no hover) | Trash button `focus-visible:opacity-100`, `pointer-events-auto` |
| T3 | show-pair-when-dirty, commit-on-ok, cancel-on-x | `dirty`, click ✓ then ✕ | `onCommit` ×1, `onCancel` ×1 |
| T4 | render-armed-delete, commit-armed-delete | `deleting`, click ✓ | Red trash rendered `aria-pressed`; `onCommit` ×1 |
| T4b | disarm-delete | `deleting`, click ✕ | `onCancel` ×1; delete disarmed without deleting |
| T4c | disarm-delete | `deleting`, click the armed red trash | `onDelete` ×1; delete disarmed without deleting |
| T5 | disable-while-busy | `dirty`, `busy`, click ✓/✕ | ✓/✕ `aria-disabled`, still focusable; clicks ignored (`onCommit`/`onCancel` not called); group `aria-busy` |
| T6 | edit-in-place, route-keyboard | type in `InlineEditableText`, press Enter, press Escape | `onChange` per edit; `onCommitEdit` ×1; `onCancelEdit` ×1 |
| T6b | route-keyboard | consumer `onKeyDown` calls `preventDefault`, press Enter | `onKeyDown` ×1; `onCommitEdit` NOT called (suppressed) |
| T7 | guard-navigation-when-dirty | guard `when`, click same-origin link | Click default-prevented; confirm dialog shown; Discard navigates (via `onNavigate`), Stay does not |
| T7b | guard-navigation-when-dirty | guard mounted, `confirmNavigation()` called | Confirm dialog shown; Discard resolves `true`, Stay resolves `false`; with no guard mounted it resolves `true` |
| T7c | guard-navigation-when-dirty | guard `when`, dispatch `popstate` | Confirm dialog shown |
| T8 | (useInlineDrafts) patch drafts | `edit(id,{enabled:true})`, base `description` changes | `changesOf` = `{enabled:true}` only (untouched `description` never sent) |
| T9 | (useInlineDrafts) settle | commit `{description:"a"}` while a newer `"ab"` is typed | after `settle(id,{description:"a"})` the row stays dirty with `"ab"` |
| T10 | (useInlineDrafts) runCommit gate + errors | re-enter `runCommit` for an in-flight row; a rejecting commit | second call no-ops; failure stores the row's error, keeps the draft |
| T11 | preserve-focus | `dirty=false`, `deletable`, click idle trash (arms delete) | The ✓ (commit) button receives focus |
| T12 | preserve-focus | pending group has focus, click ✓ (or ✕) to collapse the pair | The idle trash button regains focus |
| T13 | render-armed-delete | apply `inlineCommitDeletingClass` to the affected content while `deleting` | Content class list includes `opacity-50` and `line-through` |

`@adh-sdk/ui` `src/__tests__/inlineCommitControl.test.tsx`,
`src/__tests__/unsavedChangesGuard.test.tsx`, and
`src/__tests__/useInlineDrafts.test.tsx` implement these vectors.

