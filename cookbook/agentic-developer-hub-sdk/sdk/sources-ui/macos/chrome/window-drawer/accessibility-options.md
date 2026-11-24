
| Option | Behavior |
|--------|----------|
| Reduce Motion | NSSegmentedControl animation is system-controlled; AppKit honors system motion settings automatically. NSDrawer slide animation respects system reduce-motion preference. |
| Increase Contrast | Tab strip uses NSSegmentedControl system styling; increased contrast is handled by AppKit's theme system. Bezel uses theme's `windowBackground` role, which respects contrast settings. |
| Differentiate Without Color | Segments are labeled with text and images; selection is shown by both color and a filled segment state (not color alone). |

