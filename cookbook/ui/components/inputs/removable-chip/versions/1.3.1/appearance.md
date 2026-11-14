
```
┌──────────────────────┐
│  design-review   ✕   │   ← Badge body + trailing ✕ button
└──────────────────────┘
   value            remove
```

- Body: the shared `Badge` with `flex items-center gap-1` merged in, so the label and
  ✕ sit inline with a small gap; the badge supplies the pill (mono, uppercase,
  bordered) and the tone.
- Remove button: `text-apt-text-muted hover:text-apt-text`, `disabled:pointer-events-none`;
  contains a lucide `X` icon sized `11`, marked `aria-hidden`.
- Tone follows the `variant` prop (`neutral` default; also `accent`/`orange`/`blue`/
  `success`/`error`) resolved by `Badge`.
- No raw hex; no `!important`.

