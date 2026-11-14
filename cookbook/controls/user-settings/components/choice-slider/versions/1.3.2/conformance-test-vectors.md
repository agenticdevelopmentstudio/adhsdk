
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| choice-slider-001 | accept-choice-array, display-current-label | choices = [{value: "a", label: "Option A"}, {value: "b", label: "Option B"}], value = "a" | Component renders without error; caption displays "Option A" |
| choice-slider-002 | maintain-value-in-range | value = "b", choices = [{value: "a", label: "A"}, {value: "b", label: "B"}, {value: "c", label: "C"}] | Slider positioned at index 1; caption displays "B" |
| choice-slider-003 | maintain-value-in-range | value = "unknown", choices = [{value: "a", label: "A"}, {value: "b", label: "B"}] | Slider positioned at index 0; caption displays "A" (first choice is default) |
| choice-slider-004 | fire-change-callback | Slider moved from index 0 to index 1, choices = [{value: "opt-1", ...}, {value: "opt-2", ...}] | onChange called once with argument "opt-2" |
| choice-slider-005 | display-current-label | value = "c", choices = [{value: "a", label: "Label A"}, {value: "b", label: "Label B"}, {value: "c", label: "Label C"}] | Caption element displays text "Label C" |
| choice-slider-006 | render-discrete-control | choices.length = 5 | Range input has min="0", max="4", step="1" |
| choice-slider-007 | respect-disabled-state | disabled = true | Range input element has disabled attribute; user cannot interact with slider |
| choice-slider-008 | render-label | label = "Select preference" | Label element rendered with htmlFor pointing to range input id |
| choice-slider-009 | render-hint | hint = "Choose your preferred option" | Hint text rendered in paragraph with class aws-field__hint |
| choice-slider-010 | custom-id | id = "my-slider" | Range input has id="my-slider" |
| choice-slider-011 | render-discrete-control, edge case: Empty choices array | choices = [] | Range input renders inert with min="0", max="0"; caption is empty; onChange is never invoked |
| choice-slider-012 | maintain-value-in-range, edge case: Single choice | choices = [{value: "only", label: "Only Option"}], value = "only" | Range input has min="0", max="0" (slider cannot move); caption displays "Only Option" |
| choice-slider-013 | fire-change-callback; Keyboard support (Accessibility) | choices = [{value: "a", label: "A"}, {value: "b", label: "B"}, {value: "c", label: "C"}], value = "a", input focused, ArrowRight pressed once | Slider moves to index 1; onChange called once with argument "b" |
| choice-slider-014 | maintain-value-in-range, edge case: Number vs. string values | choices = [{value: 1, label: "One"}, {value: 2, label: "Two"}], value = "1" (string) | Strict-equality match fails against both entries; slider positioned at index 0; caption displays "One" |
| choice-slider-015 | fire-change-callback, edge case: onChange called during render | choices = [{value: "a", label: "A"}, {value: "b", label: "B"}], component re-rendered with a new `value` prop and no user interaction | onChange is not invoked |

