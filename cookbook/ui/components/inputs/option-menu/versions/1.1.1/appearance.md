
Closed:

```
┌─────────────────────────────┐
│ Search engine            ▾  │   ← trigger button (label = current value or placeholder) + chevron
└─────────────────────────────┘
```

Open, no "Other":

```
┌─────────────────────────────┐
│ Search engine            ▴  │
├─────────────────────────────┤
│ ✓ Search engine             │   ← checkmark = committed value
│   Social media              │   ← highlighted row = roving selection
│   Blog post                 │
│   Newsletter                │
└─────────────────────────────┘
```

Open, with editable "Other" as the last item:

```
┌─────────────────────────────┐
│   Search engine             │
│   …                         │
│   Word of mouth             │
│ ✓ Other                     │   ← check moves here once the user types
│   [                      ]  │   ← text input — focused on open
│   [          OK          ]  │   ← disabled until the input is non-empty
└─────────────────────────────┘
```

- Trigger: same visual language as `Select`/`Input` — surface-role border and background, focus ring in the accent tone, chevron icon in the muted-text tone.
- Surface: `Popover` content; rows use the dropdown row treatment — highlighted row uses the accent tone at low opacity, text in the default tone, check icon in the accent tone.
- Other input: shared `Input`. OK: shared `Button`, small size, accent (default) variant, full width of the surface, `disabled` when empty.
- Spacing from the standard space scale; small corner radius. No raw hex values; no style overrides that bypass the token system.

See **React/Web** under Platform Notes for the concrete design tokens this implementation uses.

