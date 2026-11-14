
| State | Appearance change |
|---|---|
| Idle | the resting variant appearance |
| Hover | variant hover treatment (e.g. `hover:bg-primary-bright`) |
| Focus-visible | focus ring (`ring-3 ring-ring/50`, `border-ring`) |
| Pressed (pointer held inside) | `data-pressed` set → dips `translate-y-px` + `brightness-95` |
| Held but pointer left | `data-pressed` cleared → returns to the resting look while still armed |
| Disabled | `pointer-events-none`, `opacity-50` |
| Invalid (`aria-invalid`) | `aria-invalid:border-destructive/50 aria-invalid:ring-3 aria-invalid:ring-destructive/40` |
| Popup trigger (`aria-haspopup`) | no pressed dip even while held |

