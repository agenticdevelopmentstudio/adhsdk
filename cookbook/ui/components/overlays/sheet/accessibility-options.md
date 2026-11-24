
| Option | Behavior |
|--------|----------|
| Reduce Motion | Sheet respects the `--apt-anim-scale` custom property, which can be set to 0 by the application to disable animations for users who prefer reduced motion. |
| Increase Contrast | Overlay opacity (`bg-black/20`) and text contrast rely on the underlying design token system; no component-level contrast override is implemented. |
| Differentiate Without Color | Component does not rely on color alone to communicate state; positional and structural changes are visible independently of color. |

