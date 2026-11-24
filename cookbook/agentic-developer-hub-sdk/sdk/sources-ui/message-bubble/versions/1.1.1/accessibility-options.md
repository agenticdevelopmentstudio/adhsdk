
| Option | Behavior |
|--------|----------|
| Reduce Motion | Streaming caret and state transitions are not animated; no change needed |
| Increase Contrast | Component respects theme colors; themes that support high-contrast modes will render at increased contrast automatically. Caller is responsible for ensuring theme provides sufficient contrast |
| Differentiate Without Color | Component uses color to distinguish user vs. persona; themes that support this mode must provide additional visual cues (position, icon, typography). Component does not enforce this |

