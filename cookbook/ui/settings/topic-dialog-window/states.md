
| State | Appearance change |
|-------|------------------|
| Default | Window not yet shown; OK enabled; problem line hidden; help button hidden |
| Presenting app-modally | Window key and front, toolbar and help drawer present, other windows held up |
| Shown as a window | Same as presenting, with other windows usable |
| Sheet | No toolbar, title hidden, help button visible at the bottom left, problem line offset right of it |
| Problem showing | The problem line shows the sentence in red; the dialog stays open |
| Awaiting save (onOK called) | OK disabled until the owner re-enables it or finishes |
| Finished | Window ordered out; `isFinished` true; owner closures released |
| Pressed | Standard push button pressed appearance, drawn by the system |
| Disabled | OK disabled while a save is in flight; Cancel is never disabled |
| Focused | Not applicable: the dialog sets no focus order of its own; OK is the default button through its Return key equivalent |
| Loading | Not applicable: the dialog shows no spinner; the awaiting-save state is only OK disabled |

