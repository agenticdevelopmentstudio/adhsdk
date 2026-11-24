
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: This component does not animate. The state transitions (loading → ready/empty/error) are instantaneous DOM swaps, not CSS animations or transitions. |
| Increase Contrast | Applied by the reading theme palette (READING_THEME.palette includes contrast-optimized colors); no component-specific handling is needed. |
| Differentiate Without Color | Applied by the reading theme palette and MarkdownRenderer output (semantic HTML markup does not rely on color alone). |

