
| Option | Behavior |
|--------|----------|
| Reduce Motion | Transitions and animations are still applied by dnd-kit (CSS transitions on transform and opacity). A consume-media-query hook or prefers-reduced-motion CSS class in the host app can disable these separately. |
| Increase Contrast | Grip handle's focus ring uses apt-gold/25; contrast may be insufficient for WCAG AA. Host app SHOULD apply a higher-contrast focus ring via CSS override if required. |
| Differentiate Without Color | Grip's hover state uses color change only; consider adding an outline or underline in the host app if users cannot distinguish color. |

