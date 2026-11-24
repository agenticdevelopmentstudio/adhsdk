
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| stepper-001 | accept-numeric-value | value=5 | Input displays "5" |
| stepper-002 | call-onchange-handler | User clicks increment button, value=5, step=1 | onChange called with 6 |
| stepper-003 | call-onchange-handler | User clicks decrement button, value=5, step=1 | onChange called with 4 |
| stepper-004 | clamp-to-bounds | User types "15" in input, min=0, max=10 | onChange called with 10 (value clamped to max) |
| stepper-005 | clamp-to-bounds | User types "-5" in input, min=0, max=10 | onChange called with 0 (value clamped to min) |
| stepper-006 | respect-step-size | User increments, value=0, step=5, max=20 | onChange called with 5 |
| stepper-007 | respect-step-size | User decrements, value=10, step=3, min=0 | onChange called with 7 |
| stepper-008 | disable-decrement-at-min | value=0, min=0 | Decrement button disabled |
| stepper-009 | disable-increment-at-max | value=10, max=10 | Increment button disabled |
| stepper-010 | disable-all-controls-when-disabled | disabled=true | Input, decrement button, increment button all disabled |
| stepper-011 | support-direct-input | User types "42" in input, min=0, max=100 | onChange called with 42 |
| stepper-012 | support-direct-input | User types "abc" in input | Input ignores non-numeric input; value unchanged |
| stepper-013 | support-optional-label | label="Quantity" | Label element rendered and associated with input |
| stepper-014 | support-optional-hint | hint="Enter a value between 1 and 10" | Hint text displayed below stepper |
| stepper-015 | custom-classname | className="my-stepper" | Custom class applied to wrapper element |
| stepper-016 | custom-id | id="order-qty" | Input element has id="order-qty"; label htmlFor="order-qty" |
| stepper-017 | clamp-to-bounds | User types "25" in input, max=20 | Value clamped to 20; onChange called with 20 |
| stepper-018 | keyboard-arrow-step | User presses ArrowUp with input focused, value=5, step=1 | onChange called with 6 (native `<input type="number">` spin behavior) |
| stepper-019 | respect-step-size | User clicks increment, value=0.2, step=0.1 | onChange called with 0.30000000000000004 (no rounding is performed; result reflects raw floating-point addition) |
| stepper-020 | support-direct-input | User clears the input (types ""), value=7, min=5 | onChange called with 5 (empty string parses to 0, then clamped to min) |
| stepper-021 | clamp-to-bounds | User types "5" (first keystroke while entering "50"), min=10 | onChange called with 10 immediately after the first keystroke, before the second digit is typed |

