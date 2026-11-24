
| State | Appearance change |
|---|---|
| Rest (unpressed) | Muted text (`text-apt-text-muted`) on the transparent pill |
| Hover | Text brightens to `text-apt-text` |
| Focus-visible | Gold focus ring (`ring-2 ring-apt-gold/40`) |
| Pressed (selected) | Gold fill: `bg-apt-gold` + `text-apt-bg` |
| Pressed + hover | Pressed treatment MUST hold, so hovering a pressed item keeps legible text on the gold fill (vector T16). In the Tailwind source this relies on `data-[pressed]:text-apt-bg` following `hover:text-apt-text` in the variant order. |
| Disabled | `opacity-50`, `pointer-events-none` |

