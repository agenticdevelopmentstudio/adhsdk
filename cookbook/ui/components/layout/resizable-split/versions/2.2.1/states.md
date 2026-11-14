
| State | Appearance change |
|---|---|
| Idle | divider `bg-apt-border` |
| Divider hover | seam `bg-apt-border-strong`; grip pill opacity 100% |
| Dragging | `cursor: row-resize`; touch-action: none blocks touch-scroll on both variants; text selection also suppressed via `select-none` on the header bar; no animation (direct manipulation) |
| Handle focused | divider receives `tabIndex=0`; browser focus ring |
| Expanded | bottom pane visible at the current ratio; chevron icon `ChevronDown` |
| Collapsed | bottom pane height 0 (still mounted, `inert`); top fills; chevron icon `ChevronUp`; header bar (if any) stays visible |
| Toggling | boundary animates 0.3s ease-in-out via `flex-basis` transition; skipped under `html[data-reduce-motion="on"]` |

