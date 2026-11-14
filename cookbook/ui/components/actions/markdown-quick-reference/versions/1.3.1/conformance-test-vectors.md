
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-labelled-trigger, start-closed | Render the control | One button named `Markdown quick reference`; no `Markdown quick reference` caption text in the DOM |
| T2 | open-on-trigger, list-common-syntax | Click the trigger | The popover shows the caption plus all nine labels: `Headings`, `Bold`, `Italic`, `Inline code`, `Code block`, `Bullet list`, `Numbered list`, `Link`, `Blockquote` |
| T3 | dismiss-on-escape, restore-focus | Open, then press Escape | The popover content is removed; focus returns to the trigger |
| T4 | honor-custom-trigger-label | Render with `triggerLabel="Syntax"` | The trigger shows `Syntax` but is still named `Markdown quick reference` |
| T5 | dismiss-on-outside-click, restore-focus | Open, then click a point outside the popover | The popover content is removed; focus returns to the trigger |

