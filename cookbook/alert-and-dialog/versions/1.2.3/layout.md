
Single-button alert (button spans the content width):

```
┌───────────────────────────────────┐
│  Title (apt-gold)                  │   ← highlight-color header
│  Body copy, proportional padding.  │
│  [               OK              ] │   ← full-width gold
└───────────────────────────────────┘
```

Two-button confirm (equal width):

```
┌───────────────────────────────────┐
│  Title (apt-gold)                  │
│  Body copy.                        │
│  [    Cancel    ][      OK       ] │   ← equal width; OK = gold
└───────────────────────────────────┘
```

Wide dialog (content wide enough that both buttons fit at their natural width → buttons keep natural width and right-justify):

```
┌─────────────────────────────────────────────────────────┐
│  Title (apt-gold)                                         │
│  … wider content …                                       │
│                              [  Cancel  ][     OK      ]  │
└─────────────────────────────────────────────────────────┘
```

- **Header**: title in the highlight color (`apt-gold`), `font-semibold`. An optional `tone` icon (info/success/error) sits to the left of the title.
- **Size**: width is proportional to content with a sensible default cap (`max-w-md` for alerts; composed dialogs may set their own). Height hugs content.
- **Padding**: consistent interior padding from `--space-*` (≈ `p-6`); footer separated by a `--space` gap; no ad-hoc values.
- **Tokens**: header `apt-gold`; body `apt-text` / `apt-text-muted`; surface `apt-surface`; border `apt-border`. Action gold (`variant="default"`) normally, red (`apt-red`) when destructive; Cancel `ghost`/`outline`. Built on the existing `Dialog` (Base UI). No raw hex; no `!important`.

