
| State | Appearance change |
|-------|------------------|
| Closed (open=false) | `opacity: 0`, `pointer-events: none` — overlay is invisible and non-interactive |
| Open (open=true) | `opacity: 1`, `pointer-events: auto` — fades in over `0.3s` (`cubic-bezier(0.16, 1, 0.3, 1)`) and becomes interactive |
| Close button — pressed (`:active`) | Text color changes from `var(--text-muted, #8a8a9a)` to `var(--accent, #c4a35a)` |

