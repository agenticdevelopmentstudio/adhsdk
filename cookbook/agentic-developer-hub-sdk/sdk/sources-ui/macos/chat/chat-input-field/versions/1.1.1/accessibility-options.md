
| Option | Behavior |
|--------|----------|
| Reduce Motion | (iOS/macOS/web) Block caret SHOULD blink less frequently or not at all when Reduce Motion is enabled; standard bar caret is not animated. Not yet implemented in source — `ChatInputField`'s blink timer runs unconditionally, with no check of the system's reduced-motion preference; the `reduced-motion` compliance check below is marked failed for this gap. |
| Increase Contrast | (iOS/macOS/web) Focus border and interactive state colors SHOULD be more saturated; text contrast ratio SHOULD exceed 7:1 |
| Differentiate Without Color | (iOS/macOS/web) Focus state MUST be indicated by border thickness or pattern change in addition to color; disabled state MUST use opacity or pattern, not color alone |

