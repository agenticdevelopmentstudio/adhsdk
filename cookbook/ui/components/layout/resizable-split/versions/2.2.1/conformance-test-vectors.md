
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | drag-clamps-ratio | drag past the minimum (0%) | ratio clamps at `minRatio` (default 0.2) |
| T2 | drag-clamps-ratio | drag past the maximum (100%) | ratio clamps at `maxRatio` (default 0.85) |
| T3 | collapse-toggles-bottom | click the chevron | bottom hidden (height 0); `aria-expanded="false"` |
| T4 | collapse-toggles-bottom | click the chevron again | bottom visible (height restored); `aria-expanded="true"` |
| T5 | persist-ratio-when-keyed | set `storageKey`, drag to 0.5, unmount, remount | ratio restores to 0.5 from `localStorage` |
| T6 | keyboard-nudges-ratio | focus divider, press ↑ | ratio nudges down by 0.03, clamped |
| T7 | keyboard-nudges-ratio | focus divider, press ↓ | ratio nudges up by 0.03, clamped |
| T8 | drag-captures-pointer | pointer-down on divider, move mouse, pointer-up | split ratio follows the pointer throughout; motion past 3px is tracked internally |
| T9 | keyboard-toggles-collapse | focus chevron button, press Enter | collapse toggles |
| T10 | keyboard-toggles-collapse | focus chevron button, press Space | collapse toggles |
| T11 | header-bar-variant | render with `header="Details"` | the separator renders as a bar containing the title; chevron is inside, far right |
| T12 | header-bar-always-visible | collapse the header-bar variant | the bar (title + chevron `⌃`) renders; bottom is `inert`, height 0 |
| T13 | header-bar-drag-anywhere | pointer-down on `headerActions` button element | no drag starts; the button's native click fires |
| T14 | expand-to-content | collapsed; content `scrollHeight` 300px in 1000px container (28px bar); expand | top pane ratio ≈ 0.672 = 1 − (300 + 28) / 1000 |
| T15 | bottom-stays-mounted | collapse the component | bottom content remains in the DOM inside an `overflow-hidden` wrapper with `inert` attribute |
| T16 | toggle-animates | set `html[data-reduce-motion="on"]`, toggle collapse | boundary animates with zero duration (no transition style applied) |
| T17 | toggle-animates | toggle collapse with `html[data-reduce-motion]` unset | boundary animates 0.3s ease-in-out |
| T18 | drag-cursor-and-no-select | drag the divider | cursor shows `row-resize`; `touch-action: "none"` blocks touch-scroll; the header-bar variant additionally suppresses text selection via `user-select: none` |
| T19 | chevron-toggle-suppressed-by-drag | press on the chevron, move 5px, release | no toggle occurs (collapse state unchanged) |
| T20 | bottom-stays-mounted | mount bottom with internal state (e.g. an input's typed value), collapse, then expand | the input's value is unchanged (the bottom pane was never unmounted) |
| T21 | drag-releases-on-pointerup | pointer-down, drag, pointer-up | `releasePointerCapture()` is called with the same `pointerId` that was captured |
| T22 | drag-maps-to-ratio | container top at `clientY=0`, height 1000px; pointer-move to `clientY=400` | ratio updates to 0.4 |
| T23 | collapse-remembers-ratio | drag to ratio 0.5, collapse, then expand (seam, `expandToContent` off) | ratio restores to 0.5, not the default |

