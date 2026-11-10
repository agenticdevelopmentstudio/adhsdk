
| Option | Behavior |
|--------|----------|
| Reduce Motion | iOS's 0.25s `view.alpha` fade (`open(animated:)`/`close(animated:)`) and web's 0.3s slide transition (`.pc-mobile-overlay` transform) both run unconditionally in this source — neither checks `UIAccessibility.isReduceMotionEnabled` (iOS) nor the `prefers-reduced-motion` media query (web). Implementations MUST check the platform's reduced-motion signal and make the transition instant when it is enabled. |
| Increase Contrast | Divider and surface colors are determined by the semantic palette; implementations MUST ensure the `border` and `chatSurface` tokens meet WCAG AA contrast requirements when Increase Contrast is enabled. |
| Differentiate Without Color | Message alignment (left/right) is the primary distinction between local and remote messages; color MUST NOT be the only differentiator. |

