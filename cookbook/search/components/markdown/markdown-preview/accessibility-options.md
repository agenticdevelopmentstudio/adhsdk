
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: This component does not animate. The state transitions (loading → ready/empty/error) are instantaneous DOM swaps, not CSS animations or transitions. |
| Increase Contrast | Not handled by this component. The reading theme is fixed at module scope and does not respond to a contrast preference; no contrast ratio is claimed (see the `contrast-ratio` check under Compliance). |
| Differentiate Without Color | Applied by the reading theme palette and MarkdownRenderer output (semantic HTML markup does not rely on color alone). |

