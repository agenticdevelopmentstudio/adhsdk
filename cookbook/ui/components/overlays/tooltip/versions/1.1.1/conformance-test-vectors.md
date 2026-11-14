
| ID | Requirements | Input | Expected |
|----|----|-------|----------|
| tooltip-001 | render-on-hover | User hovers over a trigger element within a `TooltipProvider` | Tooltip content displays after the provider's configured delay (default 200ms) |
| tooltip-002 | render-on-focus | User presses Tab to focus a trigger element | Tooltip content displays after the provider's configured delay |
| tooltip-003 | respect-provider-delay | `TooltipProvider` with `delay={500}` wraps a trigger | Tooltip does not appear until 500ms after hover begins |
| tooltip-004 | not-clipped-by-ancestors | A tooltip is rendered within a nested container with `overflow: hidden` | Tooltip content is not clipped and renders outside the container's bounds |
| tooltip-005 | position-relative-to-trigger | `TooltipContent` with `side="bottom"` and `sideOffset={8}` | Tooltip appears below the trigger, 8px from its bottom edge |
| tooltip-006 | position-relative-to-trigger | `TooltipContent` with `align="start"` | Tooltip's leading edge aligns with the trigger's leading edge |
| tooltip-007 | support-style-override | `TooltipContent` with `className="custom-bg"` where custom-bg sets background to red | Content renders with red background instead of default `apt-surface-2` |
| tooltip-008 | show-arrow | `TooltipContent` with default props (no `arrow` prop) | Diamond pointer is rendered adjacent to the content |
| tooltip-009 | show-arrow | `TooltipContent` with `arrow={false}` | No pointer element is rendered |
| tooltip-010 | render-children-in-content | `TooltipContent` with `children="Help text"` | The text "Help text" appears inside the tooltip |
| tooltip-011 | dismiss-on-escape | Tooltip is open; user presses Escape | Tooltip closes |
| tooltip-012 | remain-open-on-content-hover | Tooltip is open; user moves the pointer from the trigger onto the tooltip content | Tooltip remains open |
| tooltip-013 | dismiss-on-pointer-leave-or-blur | Tooltip is open via hover; user moves the pointer off both the trigger and the content without pressing Escape | Tooltip closes |
| tooltip-014 | position-relative-to-trigger | Document `dir="rtl"`; `TooltipContent` with `align="start"` | Tooltip's leading edge (the trigger's right edge in RTL) aligns with the trigger's leading edge |
| tooltip-015 | renders-with-empty-content | `TooltipContent` with `children=""` | Tooltip still renders and positions normally, with no visible text content |
| tooltip-016 | very-long-text-wraps | `TooltipContent` with `children` text longer than 320px wide | Tooltip wraps text onto multiple lines and grows vertically without exceeding `max-w-xs` |
| tooltip-017 | single-open-tooltip | User moves the pointer rapidly between two trigger elements within the same `TooltipProvider` before the first tooltip's delay elapses | Only one tooltip is open at a time; the delay timer resets for the newly hovered trigger |
| tooltip-018 | auto-flip-near-viewport-edge | `TooltipContent` with `side="bottom"` on a trigger near the bottom edge of the viewport | Positioner flips the tooltip to the opposite or best-fit side so it stays within the viewport |
| tooltip-019 | arrow-rotates-per-side | `TooltipContent` with `side="bottom"` | Arrow rotates 225deg to point upward toward the trigger instead of 45deg |
| tooltip-020 | disabled-trigger-not-observed | Trigger's `disabled` attribute is set to true while its tooltip is open, with no pointer-leave, blur, or Escape event | Tooltip does not close on its own |

