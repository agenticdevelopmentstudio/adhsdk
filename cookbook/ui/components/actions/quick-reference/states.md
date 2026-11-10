
| State | Appearance change |
|-------|------------------|
| Default (closed) | Trigger button displays in outline style. Popover is hidden. |
| Open | Popover is visible above, below, or beside the trigger (per `side` and `align` props). The trigger reflects `aria-expanded="true"` and switches to the muted background/foreground treatment (outline variant's `aria-expanded:` styling). |
| Hover | Trigger background lightens (`hover:bg-input/50`) and text moves to full foreground color (outline variant hover styling). |
| Pressed | The trigger does not get the usual dip/brighten pressed treatment — buttons carrying `aria-haspopup` are excluded from it (`not-aria-[haspopup]` in the shared button styles), though `data-pressed` is still set while held. |
| Focused | Trigger button receives keyboard focus and shows a focus ring (`focus-visible:ring-3`), inherited from the button element. |

