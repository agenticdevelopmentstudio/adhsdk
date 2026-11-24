
The only test beside the source, `testTheFooterHostWrapsTheTabsBesideTheShelf` in `ProjectFooterStatusTests`, asserts that a project window's content controller is this type. The other vectors are derived from the source's behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| split-001 | content-pane, shelf-leading-pane (`testTheFooterHostWrapsTheTabsBesideTheShelf`) | Build a project window controller | Its content controller is this component (the test's assertion); the shelf pane sits before the content pane by construction |
| split-002 | shelf-optional, has-shelf, no-shelf-not-visible | Construct with no shelf | One pane exists; has-shelf is false; shelf-visible is false |
| split-003 | set-visible-no-shelf, panel-toggle-no-shelf | With no shelf, request show and toggle a panel, each with a completion | Nothing changes; neither completion runs |
| split-004 | shelf-visibility-restored | Persisted visibility false (default); construct with a shelf | The shelf pane is collapsed |
| split-005 | shelf-visibility-restored | Persisted visibility true; construct with a shelf | The shelf pane is uncollapsed |
| split-006 | shelf-width-restored | Persisted width 300; construct with a shelf and show it | The shelf opens at 300 points |
| split-007 | shelf-width-bounds, open-width-clamped | Persisted width 100, then 900; show the shelf | It opens at 180 points, then at 480 points |
| split-008 | set-visible-noop | Shelf hidden, no slide; request hidden with a completion | No state change; the completion has run synchronously |
| split-009 | set-visible-persists | Shelf hidden; request visible | Persisted visibility is true before the first slide frame |
| split-010 | is-shelf-visible-target | Request hide on a visible shelf and read visibility before the slide lands | Visibility reads false although the pane is not yet collapsed |
| split-011 | toggle | Shelf visible; toggle twice in the same run loop turn | Final destination is visible; at most one slide ran per destination |
| split-012 | same-direction-joins | Request visible twice with completions A then B during one slide | One slide runs; A runs then B when it lands |
| split-013 | opposite-supersedes | Request visible with completion A, then hidden before it lands | The first slide lands at once; A never runs; the shelf slides out |
| split-014 | slide-duration, slide-easing | Run a slide in with a fake display link at t = 0, 0.1 and 0.2 seconds | Width is 0, half the open width (smoothstep at 0.5), and the open width |
| split-015 | slide-through-width, slide-width-priority | Inspect during a slide | The shelf host's requested width is at priority 999 and the divider position is not set |
| split-016 | slide-end-restore, slide-end-order | Let a slide out land | Pane collapsed; minimum thickness 180; requested width equals the clamped open width at the drag-beatable priority; did-move, visibility callback, then completion in that order |
| split-017 | no-window-immediate | Request visible on a controller whose view is in no window | The pane is uncollapsed immediately; the visibility callback and completion have run; no slide exists |
| split-018 | width-remembered-on-drag | Drag the visible shelf to 260 points | Persisted width is 260 and the requested width is 260 |
| split-019 | width-ignored-below-minimum, width-ignored-while-animating | Resize notification arrives with the shelf at 0 width, and another during a slide | Persisted width is unchanged both times |
| split-020 | move-not-for-window-resize | Resize the window | Neither move callback runs and the shelf width is unchanged |
| split-021 | drag-settle, drag-settle-restart | Three drag steps 100 milliseconds apart | Will-move runs at the start of each step (each is a width-preserving resize while no slide holds the shares); did-move runs once, 250 milliseconds after the last step |
| split-022 | slide-owns-callbacks | Drag-detected resize arrives during a slide | Neither callback runs from drag detection |
| split-023 | adopt-visibility, adopt-width | Adopt a layout of visible at 300 points onto a collapsed shelf | The shelf uncollapses at once, width 300, divider at 300, will-move then did-move run, visibility callback runs once |
| split-024 | adopt-width | Adopt a visible layout of 100 points | The shelf's visibility is applied; its width is not applied |
| split-025 | shelf-layout-snapshot | Read the layout with no shelf, then with a visible 260-point shelf | Not visible and 0, then visible and 260 |
| split-026 | panel-toggle-hide, panel-toggle-show | Toggle the shelf's current panel while visible, then a different panel | The shelf hides; then the panel switches, the shelf shows and the filter takes focus once landed |
| split-027 | hide-resigns-focus | Hide the shelf while its filter has focus | The shelf has resigned focus before the first slide frame |

