
| State | Appearance change |
|-------|------------------|
| Default | Appearance determined by the CSS class set (`aws-button`, `aws-button--{variant}`) |
| Hover | Applies only when the button is not disabled (`:hover:not(:disabled)`). Primary: `filter: brightness(1.08)`. Secondary: background `--aws-surface-hover`. Destructive: background `--aws-red` with white text. |
| Focus | `:focus-visible` shows a 2px solid `--aws-accent` outline with a 2px offset; plain `:focus` has no style |
| Active/Pressed | No `:active` style is defined |
| Disabled | `:disabled` sets `opacity: 0.5` and `cursor: not-allowed`; triggered by the `disabled` HTML attribute |
