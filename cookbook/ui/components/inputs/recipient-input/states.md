
| State | Appearance (semantic) | Mode | Notes |
|-------|-----------------------|------|-------|
| Default | field-shell border, no ring | Both | Container in fused mode or recipients box in separate mode |
| Focus-within | focus-accent border + ring | Fused | Applied when any descendant element receives focus |
| Focused (input) | Input primitive's own focus-accent | Separate | Delegated entirely to the separate Input element |
| Disabled | disabled token (reduced opacity, non-interactive) | Both | Applies to the whole component, chips and input alike |
| Chip (valid) | neutral-chip token | Both | No validation error |
| Chip (invalid) | error-chip token + `aria-invalid` | Both | Validation failed; still added to the value array |
| Empty recipients | placeholder-text ("No recipients yet") | Separate | Fused mode shows its placeholder inside the input instead of a standalone message |

