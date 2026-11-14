
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| popover-001 | open-visible | `open={true}` (full-featured) | `PopoverContent` is present in the DOM |
| popover-002 | open-visible | `open={true}` (lightweight) | Panel has the `hover-popover--open` class; opacity/visibility at full/normal |
| popover-003 | hide-on-close-unmount | `open={false}` (full-featured) | `PopoverContent`'s DOM subtree is absent (Base UI default `keepMounted={false}`) |
| popover-004 | hide-on-close-visibility | `open={false}` (lightweight) | Panel markup remains in DOM; opacity:0, visibility:hidden; no `hover-popover--open` class |
| popover-005 | placement | `side="top"` (full-featured) | Panel appears above the trigger element |
| popover-006 | placement | `side="bottom"` (full-featured) | Panel appears below the trigger element |
| popover-007 | placement | `side="left"` (full-featured) | Panel appears to the left of the trigger element |
| popover-008 | placement | `side="right"` (full-featured) | Panel appears to the right of the trigger element |
| popover-009 | placement | `placement="top"` (lightweight, default) | Panel appears above the trigger element |
| popover-010 | placement | `placement="bottom"` (lightweight) | Panel appears below the trigger element |
| popover-011 | render-children | `children={<p>Content text</p>}` (full-featured) | Child content is rendered and visible inside the panel |
| popover-012 | render-children | `children={<p>Content text</p>}` (lightweight) | Child content is rendered and visible inside the panel |
| popover-013 | side-offset | `sideOffset={16}` (full-featured) | Gap between panel edge and trigger element is 16px |
| popover-014 | alignment | `align="start"` (full-featured) | Popover's start edge aligns with trigger's start edge |
| popover-015 | alignment | `align="center"` (full-featured, default) | Popover center aligns with trigger center along the perpendicular axis |
| popover-016 | alignment | `align="end"` (full-featured) | Popover's end edge aligns with trigger's end edge |
| popover-017 | custom-styling | `className="custom-popover-class"` (full-featured or lightweight) | Custom class is applied to the panel element alongside default classes |
| popover-018 | arrow | `arrow={true}` (full-featured) | Diamond pointer (8px square, rotated per `side`) appears at the edge of the panel facing the trigger |
| popover-019 | arrow | `arrow={false}` (full-featured, default) | No pointer element is rendered |
| popover-020 | dialog-role | Popover rendered via `PopoverContent` (full-featured) | Inspect DOM; the `Popover.Popup` element has `role="dialog"` |
| popover-021 | return-focus-on-close | Popover open (full-featured, non-modal), Tab from the first focusable element inside the panel through the last | Focus moves forward through the panel's focusable elements in DOM order; it does not cycle back to the first panel element (no focus trap) |
| popover-022 | return-focus-on-close | Popover open (full-featured), focus on the last focusable element inside the panel, press Tab | Focus leaves the panel and moves to the next tabbable element after the trigger in document tab order; the popover closes (Base UI's `focus-out` dismissal); return-focus is suppressed, so focus does NOT go back to the trigger element (contrast Escape, which does return focus to the trigger) |
| popover-023 | escape-closes | Popover open (full-featured, controlled via `open`/`onOpenChange`), press Escape | `onOpenChange(false, ...)` is called; the consumer setting `open` to `false` in response causes `PopoverContent` to unmount |
| popover-024 | aria-expanded | Popover open (full-featured) | Trigger element has `aria-expanded="true"` |
| popover-025 | aria-expanded | Popover closed (full-featured) | Trigger element has `aria-expanded="false"` |

