
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| slider-001 | range-input | value=50, min=0, max=100, step=1 | `<input type="range" value="50" min="0" max="100" step="1">` is rendered |
| slider-002 | accept-value | Controlled component with value=75 | Input element's `.value` DOM property equals `"75"` |
| slider-003 | change-callback | User drags input to value 60 | `onChange` callback is invoked with `60` |
| slider-003a | change-callback | User drags input to value 60 | `onChange` is invoked with an argument whose `typeof` is `'number'` (the raw `event.target.value` string is converted before the callback fires) |
| slider-004 | optional-label | label="Volume" | A `<label>` element is rendered with a `for` attribute (the DOM attribute; `htmlFor` is the React prop name) equal to the input's `id`, and text content "Volume" |
| slider-005 | optional-hint | hint="Adjust volume from 0–100" | Hint text is rendered as `<p class="aws-field__hint">...</p>`, the last child of the wrapper |
| slider-006 | optional-caption (static) | caption="Volume: 50" | Caption "Volume: 50" is rendered as `<span class="aws-slider__caption">...</span>` |
| slider-007 | optional-caption (dynamic) | caption={(val) => `Level: ${val}`}, value=75 | Caption "Level: 75" is rendered (function called with current value) |
| slider-008 | disabled-state | disabled=true | Input has `disabled` attribute; user cannot interact with it |
| slider-009 | default-min | min prop not provided | `min` attribute defaults to `0` |
| slider-010 | default-max | max prop not provided | `max` attribute defaults to `100` |
| slider-011 | default-step | step prop not provided | `step` attribute defaults to `1` |
| slider-012 | generate-id | id prop not provided | Component generates a unique ID using React's `useId`; label (if present) associates to this ID |
| slider-013 | label-association | id="custom-slider", label="Value" | The rendered `<label for="custom-slider">` and `<input id="custom-slider">` share the same ID value |
| slider-014 | apply-classes | className="my-custom-class" | Wrapper has classes `aws-field aws-field--slider my-custom-class` |
| slider-015 | change-callback (boundary) | User drags to min=0 | `onChange(0)` is called |
| slider-016 | change-callback (boundary) | User drags to max=100 | `onChange(100)` is called |
| slider-017 | change-callback (keyboard) | Input focused, user presses ArrowRight (or ArrowUp) | Value increases by one `step`; `onChange` is called with the new numeric value |
| slider-018 | change-callback (keyboard) | Input focused, user presses ArrowLeft (or ArrowDown) | Value decreases by one `step`; `onChange` is called with the new numeric value |
| slider-019 | change-callback (keyboard) | Input focused, user presses Home | Value jumps to `min`; `onChange` is called with `min` |
| slider-020 | change-callback (keyboard) | Input focused, user presses End | Value jumps to `max`; `onChange` is called with `max` |
| slider-021 | change-callback (keyboard) | Input focused, user presses Page Up / Page Down | Value jumps by a browser-defined larger increment; `onChange` is called with the new numeric value |
| slider-022 | disabled-state (keyboard) | disabled=true, input focused, user presses an arrow, Home, End, or Page key | Value does not change; `onChange` is not called |

