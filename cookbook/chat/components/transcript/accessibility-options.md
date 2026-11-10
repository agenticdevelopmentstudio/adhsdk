
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the `fadeOlder` mask is a function of scroll position, not a timed animation — there is no motion for `prefers-reduced-motion` to suppress (see Appearance: the fade has no animation duration, only scroll-linked opacity). |
| Increase Contrast | The `fadeOlder` mask reduces message *opacity*; it does not introduce a color of its own to adjust. Legibility of a faded (older) message is bounded by the active theme's text/background contrast ratio at that opacity level, which Increase Contrast affects the same way it affects any other themed content. |
| Differentiate Without Color | Not applicable; Transcript does not use color alone to convey meaning. Typing status is announced via the TypingIndicator's content and `aria-label`, not color. |

