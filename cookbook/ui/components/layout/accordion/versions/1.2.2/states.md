
| State | Appearance change |
|-------|-------------------|
| Default (closed) | Chevron points downward (0 degrees); panel content hidden by overflow-hidden; trigger text in apt-text color |
| Hover | No visible color change — the trigger's hover state targets the same `apt-text` color as its default, so hovering the trigger produces no additional visual affordance beyond the pointer cursor |
| Focus (keyboard navigation) | `outline-none` suppresses the browser's default focus ring, and the trigger's focus-visible state also targets `apt-text`, matching its default — this component's own styles produce no visible focus indicator (see #requirements/support-style-override to add one via `className`) |
| Open/Expanded | Chevron rotates to 180 degrees (points upward); panel transitions open via overflow hidden animation; panel content visible |
| Closed/Collapsed | Chevron at 0 degrees (points downward); panel hidden via overflow-hidden; animation applies on close |

