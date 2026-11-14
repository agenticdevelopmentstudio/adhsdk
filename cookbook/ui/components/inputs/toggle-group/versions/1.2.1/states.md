
| State | Appearance change |
|---|---|
| Rest (unpressed) | Muted text (`text-apt-text-muted`) on the transparent pill |
| Hover | Text brightens to `text-apt-text` |
| Focus-visible | Gold focus ring (`ring-2 ring-apt-gold/40`) |
| Pressed (selected) | Gold fill: `bg-apt-gold` + `text-apt-bg` |
| Pressed + hover | Pressed treatment holds: `data-[pressed]:text-apt-bg` wins over `hover:text-apt-text`, so hovering a pressed item keeps legible text on the gold fill |
| Disabled | `opacity-50`, `pointer-events-none` |

