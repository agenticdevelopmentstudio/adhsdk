
- **Zero container extent**: If the container has zero height (horizontal) or zero width (vertical), drag calculations divide by zero. The component detects this and ignores the drag; the ratio remains unchanged until the container is resized.
- **Pointer cancel / lost capture**: If a gesture is cancelled (touch scroll takeover, window blur) or pointer capture is lost, the component ends the drag. Subsequent `pointermove` events do not resize.
- **Extreme ratios**: If `minRatio = 0` and `maxRatio = 1` (range 0–1), the entire spectrum of split sizes is allowed. If `minRatio = maxRatio`, the split is fixed and resize operations will always clamp to that single value.
- **Very large step**: If `step = 0.5`, each keyboard press moves the split by 50% of the container. The clamping logic ensures the ratio never exceeds `[minRatio, maxRatio]`.
- **Rapid key presses**: Repeated arrow key presses (e.g., held down) will call `onRatioChange` once per `onKeyDown` event, applying step adjustments in sequence. No debouncing is applied; all calls are clamped independently.
- **Simultaneous drag and key input**: If the user holds down an arrow key while dragging, both `pointermove` and `onKeyDown` will call `onRatioChange`. The component does not prevent this, and the ratio will be set by whichever input fired last.
- **Step button during drag**: `setPointerCapture` is scoped to the pointer id that started the drag, so a step-button click from that same pointer cannot occur — its `pointerdown`/`pointerup` are captured by the separator, not the button — until the drag ends. A click from a different pointer (e.g., a second touch) is independent of the drag and applies its `step` immediately.

