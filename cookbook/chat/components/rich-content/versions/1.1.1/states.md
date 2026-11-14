
| State | Appearance change |
|-------|------------------|
| Default (link) | Styled as a hyperlink; user can perceive it as interactive |
| Hovered (link) | Platform-specific hover styling (underline emphasis, color change) |
| Focused (link) | Platform-specific focus indicator (outline, highlight) |
| Active/Pressed (link) | Platform-specific pressed state |
| Image loading | Image hidden (`display: none`); no space reserved |
| Image loaded | Image displayed at its natural/CSS-constrained size |
| Image error | Hidden style removed (fail-open reveal, same as success); browser's default broken-image indicator shown; may shift surrounding layout since no space was reserved while hidden |

