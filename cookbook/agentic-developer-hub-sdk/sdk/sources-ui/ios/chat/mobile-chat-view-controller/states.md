
| State | Appearance change |
|-------|------------------|
| Default | Surface visible with all content rendered; input field ready for typing. |
| Open (animated) | iOS: surface `view.alpha` animates 0 → 1 over 0.25s. Web: `.pc-mobile-overlay` slides in, `transform: translateX(100%)` → `translateX(0)`, over 0.3s. |
| Closed (animated) | iOS: surface `view.alpha` animates 1 → 0 over 0.25s. Web: the overlay slides back out via the reverse transform transition. |
| Input focused | Native keyboard is presented (platform-specific). |
| Thinking/typing remote | Status line shows remote participant's current status or default pulsing indicator. |
| Message composing | Active draft appears in transcript with `.composing` delivery status. |

