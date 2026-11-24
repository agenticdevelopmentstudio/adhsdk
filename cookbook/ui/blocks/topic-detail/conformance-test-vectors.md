
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-two-panes | `items` and `children` | rail left, pane right, `children` in the pane |
| T2 | mark-selected | `selectedId="x"` | row x has `aria-current="true"` and gold text and bar |
| T3 | report-selection | click row "y" | `onSelect("y")` once |
| T4 | report-selection | click the already-selected row, not covered | `onSelect` fires again with the same id |
| T5 | skip-covered-reselect | `covered`, click the selected row | no `onSelect` |
| T6 | skip-disabled | click a `disabled` row | no `onSelect`; row dimmed |
| T7 | render-empty-label | `items=[]` | "Nothing here yet." in a paragraph |
| T8 | support-rail-slot | `railSlot={(c)=>...}`, `railSlotActive`, collapsed | slot above topics with gold bar; function got `true` |
| T9 | support-rail-slot | no `railSlot` | no slot element; first row at top padding |
| T10 | render-label-suffix | `{label:"A", labelSuffix:"v2"}` | "A" and "v2" on one line, both full size |
| T11 | render-inline-sublabel | `{label:"A", sublabel:"b.com", inlineSublabel:true}` | one line; sublabel dim and shrinks first |
| T12 | render-stacked-sublabel | `{label:"A", sublabel:"b.com"}` | second dim line |
| T13 | render-preview, clamp-preview | topicDetailPreview.test: `preview` with `previewLines` 2 | preview block with 2-line clamp |
| T14 | clamp-preview | `previewLines: 0`, and `previewLines: 9` | no preview; and a 4-line clamp |
| T15 | clamp-preview | `preview: "   "` | no preview block |
| T16 | render-icon | row without `icon`; row with `icon={false}` | neutral 16px ring in both |
| T17 | hide-row-icons | `hideItemIcons`, expanded; then collapsed | no icon expanded; icon present collapsed |
| T18 | hide-label-when-icon-only, tooltip-when-collapsed | `collapsed` | rows show icons only; `aria-label` = label; tooltip on hover |
| T19 | render-divider-after | `dividerAfter` expanded, collapsed and covered | separator in all three; `mx-3` expanded and covered, `mx-2` collapsed |
| T20 | render-divider-label | `dividerAfter`, `dividerLabel:"Coming soon"` | caption expanded; none in strips |
| T21 | render-spacer-after | `spacerAfter` at position 2 of 5 | rows 3-5 at the bottom edge |
| T22 | render-trailing | `trailing={<Badge/>}` | right-justified expanded; absent when collapsed |
| T23 | render-row-disclosure | `rowDisclosure` | chevron on enabled non-link rows only |
| T24 | support-link-row | topicDetailLink.test: choose a row with `onLink` | link runs; `onSelect` not called |
| T25 | support-link-row | topicDetailLink.test: choose an ordinary row | `onSelect` runs |
| T26 | flash-link-row | topicDetailLink.test: choose a link row | marked active, then released after 1000ms |
| T27 | render-link-glyph | topicDetailLink.test: link row without icon | link glyph; no chevron |
| T28 | render-blocked-marker | topicDetailBlocked.test: `blocked: true` | dot on icon; `data-blocked="true"`; "needs attention" in name |
| T29 | render-blocked-marker | `blocked`, collapsed | `aria-label` "A, needs attention" |
| T30 | render-blocked-without-icon | `blocked`, `hideItemIcons` | standalone dot; sr-only text |
| T31 | support-delete-action | topicDetailDelete.test: hover then click trash | confirm dialog opens; row not selected |
| T32 | run-delete-on-confirm | confirm with an async `onDelete` | busy until it settles, then closed |
| T33 | keep-dialog-on-delete-failure | `onDelete` rejects, confirm | dialog open, busy cleared |
| T34 | support-delete-label | `deleteLabel:"Workspace"` | "Delete Workspace" button; "Delete Workspace?" title |
| T35 | support-delete-confirm | `deleteConfirm:"Permanent loss."` | dialog body shows it; default is "This action can't be undone." |
| T36 | delete-on-disabled-row | `disabled`, `onDelete` | trash button present and enabled |
| T37 | support-delete-action | `collapsed` or `covered` with `onDelete` | no trash button |
| T38 | support-batch-mode | topicDetailCheckable.test: `checkable` | checkbox per expanded row; none in strips |
| T39 | report-batch-toggle | tick an unticked box | `onToggleChecked(id)`; no `onSelect` |
| T40 | disable-batch-check | `checkDisabled` row | box disabled; row still selectable |
| T41 | support-prefetch | topic-rail-prefetch.test: rest on a row 100ms | `onPrefetch(id)` once |
| T42 | support-prefetch | topic-rail-prefetch.test: sweep past rows | nothing fires |
| T43 | support-prefetch | topic-rail-prefetch.test: keyboard focus; and no `onPrefetch` | fires on focus; nothing without the prop |
| T44 | support-prefetch | rest on the selected row | not armed |
| T45 | support-hover-bar | `hoverBar: false` | no hover border class |
| T46 | support-marker-selection | `selectionStyle:"marker"`, `isRoot` | full-height gold bar; no gold border |
| T47 | collapse-rail | click the toggle | rail 48px; click again restores |
| T48 | support-controlled-collapse | `collapsed:true`, toggle | `onCollapsedChange(false)`; state follows the prop |
| T49 | support-drag-resize | drag to 100px, then 50px, then 400px (default 240) | tracks 100; collapses at 50; clamps to 240 |
| T50 | transition-collapse | drag in progress | transition class absent; present when idle |
| T51 | respond-mobile | width below `md` | one column; rail above; toggle and handle hidden |
| T52 | support-pane-padding | `panePadding:false` | no inset or gap classes |
| T53 | support-titled-header | `title:"Users"` on `TopicRail` | header with title; toolbar named "Users tools" |
| T54 | support-untitled-header | no title; with `backSlot`, then `leftControl` | back slot top-left; `leftControl` wins when both given |
| T55 | support-list-toolbar | topic-rail-toolbar.test: titled, no tools | toolbar with filter present |
| T56 | support-list-toolbar | topic-rail-toolbar.test: untitled; collapsed | no toolbar |
| T57 | support-list-toolbar | topic-rail-toolbar.test: with `onNew` and `titleActions` | order filter, `+`, host tools |
| T58 | support-create-affordance | `onNew`, `newLabel:"New Topic"`, `newActive` | named "New Topic"; gold |
| T59 | support-close-button | `onClose`, `closeLabel:"Dismiss"` | button named "Dismiss" |
| T60 | support-header-slot | `headerSlot`; then collapsed | strip under toolbar; hidden collapsed |
| T61 | support-footer | `footer` | pinned below the list with a top border |
| T62 | show-busy-indicator, announce-busy | topic-rail-busy.test: `busy` | spinner by the title; "Loading" announced; empty when not busy |
| T63 | label-landmark | `railLabel:"Notes"`; default | aside named "Notes"; "Topic list" |
| T64 | support-dense-bottom | `denseBottom` | `pb-2` |
| T65 | open-filter-on-mount | topic-rail-toolbar.test: `search.autoOpen` | panel open, field focused |
| T66 | suggest-matches | topic-rail-toolbar.test: type a query | matching options by label and sublabel; rail rows kept |
| T67 | underline-match | topic-rail-toolbar.test: "İstanbul" with "stan" | "stan" underlined |
| T68 | navigate-suggestions | topic-rail-toolbar.test: Down at last option | wraps to the first; caret unmoved |
| T69 | choose-suggestion | topic-rail-toolbar.test: Enter | row selected, panel closed, query cleared |
| T70 | choose-suggestion | topic-rail-toolbar.test: choose the selected row | `onSelect` not called |
| T71 | suggest-matches | topic-rail-toolbar.test: a disabled row matches | not offered |
| T72 | say-no-match | topic-rail-toolbar.test: no match | "Nothing matches" and Enter keeps the field open |
| T73 | dismiss-filter | topic-rail-toolbar.test: Escape | closed, nothing selected, focus on button, dialog not closed |
| T74 | dismiss-filter | topic-rail-toolbar.test: focus leaves; Tab onto the clear button | closes; stays open for the clear button |
| T75 | ignore-ime-enter | topic-rail-toolbar.test: Enter while composing | nothing chosen |
| T76 | support-live-filter | topic-rail-toolbar.test: `live` | rail rows narrow; selected row survives; Enter left to host |
| T77 | support-controlled-query | topic-rail-toolbar.test: controlled | `onQueryChange` per keystroke; query kept on blur; cleared once on Escape |
| T78 | wait-for-pending-rows | topic-rail-toolbar.test: `pending` | "Searching…" and no suggestions |
| T79 | tint-active-filter | query set, panel closed | filter button gold |
| T80 | fit-width | railAutoFit.test: `onFit`, rows measured | reported width in `railPx(150)`..`railPx(420)` |
| T81 | skip-fit-when-unmeasurable | topic-rail-toolbar.test: query narrows rows; collapsed | no report; whole list re-measured after clear |
| T82 | refit-on-tool-resize | topic-rail-toolbar.test: tools outgrow rows | width wide enough for the toolbar |
| T83 | pass-through-fields | `description`, `leadsTo` set | rendered output unchanged |

