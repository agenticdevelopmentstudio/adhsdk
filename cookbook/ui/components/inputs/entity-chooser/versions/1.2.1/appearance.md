
Single (closed):

```
┌─────────────────────────────┐
│ architecture            ▾   │   ← trigger: the chosen value, or the trigger label
└─────────────────────────────┘
```

Multi:

```
┌──────────┐ ┌──────────┐ ┌───────────┐
│ vision ✕ │ │ rlhf  ✕  │ │ Choose… ▾ │   ← chips (removable) + the add trigger, inline
└──────────┘ └──────────┘ └───────────┘
```

Open (both modes) — the embedded `ListChooser` surface:

```
┌─────────────────────────────┐
│ [ att|                    ]  │   ← filter/add field (focused on open)
├─────────────────────────────┤
│   attention                 │   ← filtered list (selected options omitted in multi)
│ + Add “att”                 │   ← create row, when text matches no option
├─────────────────────────────┤
│              Cancel    OK   │
└─────────────────────────────┘
```

- Trigger, surface, list rows, create row, and button bar are entirely `ListChooser`'s treatment (`apt-border`/`apt-bg`, `apt-gold` highlight + check, `ChevronsUpDown`).
- Chips are the shared `RemovableChip` component with text content and a trailing remove button.
- Multi lays chips and the `Choose…` trigger in one `flex-wrap` row; the trigger is auto-width (`w-auto`) so it sits after the chips rather than filling the row.
- All color via `apt-*` tokens; no raw hex; no `!important`.

