
| State | Appearance change | Behavioral change |
|-------|------------------|-------------------|
| Closed | Dialog not rendered or hidden | Input value is not reset; only pre-filled on next open |
| Open (default) | Dialog visible, input focused | Ready for input; error message cleared |
| Focused | Input field has focus outline | User can type or press Enter to submit |
| Loading | Input disabled, confirm button shows loading indicator | All inputs disabled; dialog cannot close |
| Validation error | Error message displayed in red below input | Input remains enabled; confirm button is disabled only when the trimmed input is empty, per **disable-confirm-when-empty** — it stays enabled while a duplicate or operation error is showing, so the user can retry immediately |
| Operation error | Error message displayed below input | Input enabled; user can edit and retry |

