
| Option | Behavior |
|--------|----------|
| Reduce Motion | The width transition duration is `200ms * var(--apt-anim-scale, 1)`, which the global reduce-motion setting zeroes; the spinner uses `animate-spin` with no override here. |
| Increase Contrast | Not applicable: colours come from shared `apt-*` tokens; the component has no contrast logic. |
| Differentiate Without Color | The blocked dot is paired with announced text, and the active row pairs the gold bar with `aria-current`. |

