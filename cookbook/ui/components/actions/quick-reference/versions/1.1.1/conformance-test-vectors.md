
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| quick-ref-001 | trigger-button-style, trigger-book-icon | Component rendered | Trigger button is visible, subdued/outline style, small size, with book icon at inline start |
| quick-ref-002 | trigger-accessible-name | ariaLabel="Markdown quick reference" | Trigger has aria-label="Markdown quick reference" |
| quick-ref-003 | popover-opens-on-click | User clicks trigger button | Popover becomes visible |
| quick-ref-004 | popover-title-display | title="Markdown Syntax" | Popover displays "Markdown Syntax" in field-caption style |
| quick-ref-005 | entries-definition-list | entries=[{label: "Bold", syntax: "**text**"}, {label: "Italic", syntax: "*text*"}] | Popover displays two rows in grid: "Bold" / "**text**" and "Italic" / "*text*" |
| quick-ref-006 | entry-label-style | Entry with label "Bold" | Label rendered at a small font size, in muted color (the code text is smaller still — see quick-ref-007) |
| quick-ref-007 | entry-code-style | Syntax with newlines: "line1\nline2" | Code block preserves newlines, uses monospace font, smaller than label text, normal line spacing |
| quick-ref-008 | escape-dismissal | Popover is open; user presses Escape | Popover closes |
| quick-ref-009 | outside-click-dismissal | Popover is open; user clicks outside popover | Popover closes |
| quick-ref-010 | focus-restoration | Popover is open; user dismisses it by pressing Escape while focus is inside the popover panel | Focus moves back to the trigger button (not to `document.body` or elsewhere) |
| quick-ref-011 | optional-trigger-label | triggerLabel="Syntax" | Trigger button displays "Syntax" text alongside icon |
| quick-ref-012 | customizable-width | contentClassName="w-96" | Popover renders with width class w-96 (24rem) instead of default w-80 |
| quick-ref-013 | customizable-columns | columnsClassName="grid-cols-[10rem_1fr]" | Entry grid uses 10rem / 1fr column split instead of default 7rem / 1fr |
| quick-ref-014 | customizable-position | side="top", align="start" | Popover opens above trigger (top) and aligns to the start of that edge |
| quick-ref-015 | customizable-trigger-classes | className="custom-trigger-class" | Trigger button receives custom-trigger-class in addition to its style and size classes |
| quick-ref-016 | popover-opens-on-click | Trigger button is focused; user presses Enter or Space | Popover becomes visible (native `button` keyboard activation) |
| quick-ref-017 | trigger-disclosure-state | Popover transitions from closed to open | Trigger's `aria-expanded` changes from "false" to "true"; trigger carries `aria-haspopup` in both states |
| quick-ref-018 | entries-definition-list | entries=[] | Popover renders the title and an empty `dl` with no `dt`/`dd` rows |

