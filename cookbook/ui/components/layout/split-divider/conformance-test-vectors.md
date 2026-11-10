
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| split-divider-001 | separator-role | Component rendered | Element with `role="separator"` is in the DOM |
| split-divider-002 | ratio-change-callback | Pointer at `clientY` = the container's top edge + 50 (per `getBoundingClientRect`); container is 200px tall | `onRatioChange` is called with ratio ≈ 0.25 (50/200) |
| split-divider-003 | ratio-clamp | `minRatio=0.2, maxRatio=0.8`; user drags to ratio 0.05 | `onRatioChange` is called with 0.2 (clamped to minRatio) |
| split-divider-004 | ratio-clamp | `minRatio=0.2, maxRatio=0.8`; user drags to ratio 0.95 | `onRatioChange` is called with 0.8 (clamped to maxRatio) |
| split-divider-005 | horizontal-orientation | `orientation="horizontal"` (default); component rendered | Separator renders as a horizontal line; `aria-orientation="horizontal"` is set; vertical drag is tracked |
| split-divider-006 | vertical-orientation | `orientation="vertical"`; component rendered | Separator renders as a vertical line; `aria-orientation="vertical"` is set; horizontal drag is tracked |
| split-divider-007 | ratio-prop | `ratio=0.5`; component rendered | `aria-valuenow="50"` (50% of the split) |
| split-divider-008 | minmax-ratio-props | `minRatio=0.1, maxRatio=0.9`; component rendered | `aria-valuemin="10"`, `aria-valuemax="90"` |
| split-divider-009 | drag-resize, drag-end-on-release | User drags the separator and releases the mouse mid-drag | Drag ends; ratio stops updating after release |
| split-divider-010 | drag-end-on-release | User drags the separator, then the primary button is released while `pointermove` events continue | Drag ends immediately; subsequent `pointermove` events do not resize |
| split-divider-011 | zero-extent-guard | `containerRef` points to a container with zero height; user attempts to drag | `onRatioChange` is not called; the ratio remains unchanged |
| split-divider-012 | keyboard-shrink | Component is focused; user presses ArrowUp (horizontal) | `onRatioChange` is called with `ratio - step` |
| split-divider-013 | keyboard-shrink | `orientation="vertical"`; component is focused; user presses ArrowLeft | `onRatioChange` is called with `ratio - step` |
| split-divider-014 | keyboard-grow | Component is focused; user presses ArrowDown (horizontal) | `onRatioChange` is called with `ratio + step` |
| split-divider-015 | keyboard-grow | `orientation="vertical"`; component is focused; user presses ArrowRight | `onRatioChange` is called with `ratio + step` |
| split-divider-016 | home-key | Component is focused; user presses Home | `onRatioChange` is called with `minRatio` |
| split-divider-017 | end-key | Component is focused; user presses End | `onRatioChange` is called with `maxRatio` |
| split-divider-018 | visual-line | Component rendered | A 3px line is visible, centered in the 24px grab area, with color `apt-border` |
| split-divider-019 | step-buttons | Component rendered | Two 24px × 24px buttons are rendered and are clickable |
| split-divider-020 | grab-cursor | `orientation="horizontal"`; component rendered | Cursor is `cursor-row-resize` over the separator |
| split-divider-021 | grab-cursor | `orientation="vertical"`; component rendered | Cursor is `cursor-col-resize` over the separator |
| split-divider-022 | grab-area-size | Component rendered with `orientation="horizontal"` | Root element has `height=24px` and `width=100%` of its container |
| split-divider-023 | grab-area-size | Component rendered with `orientation="vertical"` | Root element has `width=24px` and `height=100%` of its container |
| split-divider-024 | grab-area-focusable | Component rendered | Separator is focusable via Tab key |
| split-divider-025 | default-label | Component rendered without `label` prop | `aria-label="Resize split"` is set |
| split-divider-026 | default-label | `label="Custom Resize"`; component rendered | `aria-label="Custom Resize"` is set |
| split-divider-027 | step-button-labels | Component rendered with `orientation="horizontal"` and no custom labels | Step button labels are "Grow top pane" and "Grow bottom pane" (defaults) |
| split-divider-028 | step-button-labels | `orientation="vertical"`, `growTopLabel="Expand left"`, `growBottomLabel="Expand right"`; component rendered | Step buttons have the custom labels |
| split-divider-029 | focus-ring | Component is focused via keyboard; component rendered | A 2px `apt-gold/40` focus ring is visible around the separator |
| split-divider-030 | classname-prop | `className="custom-class"`; component rendered | Root element has class `custom-class` applied |
| split-divider-031 | keyboard-default-prevention | Component is focused; user presses ArrowDown (horizontal) | `event.preventDefault()` is called; the page does not scroll |
| split-divider-032 | step-button-mapping | `orientation="horizontal"`; user clicks the shrink button (▲) | `onRatioChange` is called with `ratio - step` |
| split-divider-033 | step-button-mapping | `orientation="horizontal"`; user clicks the grow button (▼) | `onRatioChange` is called with `ratio + step` |
| split-divider-034 | step-button-mapping | `orientation="vertical"`; user clicks the shrink button (◀) | `onRatioChange` is called with `ratio - step` |
| split-divider-035 | step-button-mapping | `orientation="vertical"`; user clicks the grow button (▶) | `onRatioChange` is called with `ratio + step` |
| split-divider-036 | step-button-pointerdown-guard | User presses the pointer down directly on a step button | The separator's drag does not start; only the button's `onClick` fires |
| split-divider-037 | drag-resize, drag-end-on-release | User is mid-drag (pointer captured); a `pointercancel` event fires (e.g., touch scroll takeover) | Drag ends; subsequent `pointermove` events do not resize |
| split-divider-038 | drag-resize, drag-end-on-release | User is mid-drag; `onLostPointerCapture` fires (capture lost) | Drag ends; subsequent `pointermove` events do not resize |
| split-divider-039 | ratio-clamp | `minRatio=0.2, maxRatio=0.8`; `ratio=0.79`, `step=0.03`; user presses the grow arrow | `onRatioChange` is called with 0.8 (clamped, not 0.82) |
| split-divider-040 | ratio-prop | `ratio=0.333` | `aria-valuenow="33"` (rounded to nearest integer) |
| split-divider-041 | zero-extent-guard | `orientation="vertical"`; `containerRef` points to a container with zero width; user attempts to drag | `onRatioChange` is not called; the ratio remains unchanged |
| split-divider-042 | focus-ring | Component receives focus via a pointer click (not Tab) | No focus ring is visible (`:focus-visible` does not match pointer-triggered focus) |
| split-divider-043 | touch-none, select-none | Component rendered | Separator element has both the `touch-none` and `select-none` CSS classes applied |
| split-divider-044 | container-ref | `containerRef.current` is `null` (not yet mounted); user attempts to drag | `onRatioChange` is not called |
| split-divider-045 | ratio-clamp | `minRatio=0.5, maxRatio=0.5`; user drags or presses any adjustment key | `onRatioChange` is always called with `0.5`, the single fixed value |
| split-divider-046 | keyboard-grow, ratio-clamp | `step=0.5`; `ratio=0.5`; `maxRatio=0.8`; user presses the grow arrow | `onRatioChange` is called with `0.8` (clamped, despite the raw step landing at 1.0) |
| split-divider-047 | keyboard-grow | Component is focused; user presses ArrowDown twice in quick succession | `onRatioChange` is called twice, once per keypress, each computed from the `ratio` prop value current at that event |
| split-divider-048 | drag-resize, keyboard-grow | User is dragging (a `pointermove` fires) while also pressing ArrowDown | `onRatioChange` is called for both the pointermove and the keydown; the ratio reflects whichever fired last |
| split-divider-049 | step-button-pointerdown-guard | A drag is in progress from pointer A; pointer B (a second touch) taps a step button | The step button's `onClick` fires immediately, independent of pointer A's drag |

