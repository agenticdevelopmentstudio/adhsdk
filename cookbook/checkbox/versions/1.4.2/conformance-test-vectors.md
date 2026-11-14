
| ID | Requirements | Layer | Input | Expected |
|----|-------------|-------|-------|----------|
| checkbox-001 | controlled-value | Wrapper | `value={true}`, no change | Checkbox renders checked (checkmark visible) |
| checkbox-002 | controlled-value | Wrapper | `value={false}`, no change | Checkbox renders unchecked (checkmark hidden) |
| checkbox-003 | change-callback | Wrapper | User clicks checkbox, `value={false}` | `onChange(true)` is called with new value |
| checkbox-004 | change-callback | Wrapper | User clicks checkbox, `value={true}` | `onChange(false)` is called with new value |
| checkbox-005 | switch-appearance | Wrapper | `appearance='switch'`, `value={false}` | Input has `role="switch"`; visual look follows the `aws-field--checkbox-switch` stylesheet rule |
| checkbox-006 | check-appearance | Wrapper | `appearance='check'`, `value={false}` | Input has implicit checkbox role; visual look follows the `aws-field--checkbox-check` stylesheet rule |
| checkbox-007 | default-appearance | Wrapper | No `appearance` prop specified | Component renders with switch appearance (`role="switch"`) |
| checkbox-008 | disabled-state | Wrapper | `disabled={true}`, user attempts click | User interaction is prevented; `onChange` is not called |
| checkbox-009 | optional-label | Wrapper | `label="Agree to terms"` | Label text renders adjacent to checkbox, associated via `htmlFor` |
| checkbox-010 | optional-label | Wrapper | No `label` prop | Label text does not render |
| checkbox-011 | optional-hint | Wrapper | `hint="Required to proceed"` | Hint text renders below checkbox in a paragraph element |
| checkbox-012 | optional-hint | Wrapper | No `hint` prop | Hint text does not render |
| checkbox-013 | label-input-association | Wrapper | User clicks on label text | Input receives focus and toggles (checked state changes) |
| checkbox-014 | visual-indicator | Primitive | `checked={true}` | `Check` icon is visible inside the indicator |
| checkbox-015 | visual-indicator | Primitive | `checked={false}` | `Check` icon is not rendered |
| checkbox-016 | focus-ring | Primitive | User tabs to the primitive | Keyboard focus ring (2px, `apt-gold/25`) is visible |
| checkbox-017 | custom-classname | Wrapper | `className="my-custom-class"` passed to the wrapper | Custom class is appended to the wrapper's root `<div>` |
| checkbox-018 | custom-id | Wrapper | `id="my-checkbox"` | Input element has `id="my-checkbox"` and label references it |
| checkbox-019 | checked-without-color | Primitive | Primitive rendered with color rendering suppressed (greyscale) | The `Check` glyph is present in the checked box and absent in the unchecked box |
| checkbox-020 | custom-classname | Primitive | `className="my-custom-class"` passed to the primitive | Custom class is merged into `CheckboxPrimitive.Root`'s class list via `cn()` |
| checkbox-021 | hint-description-association | Wrapper | `hint="Required to proceed"`, input receives focus | Input's `aria-describedby` (or platform equivalent) references the hint element, so assistive technology announces the hint text |
| checkbox-022 | controlled-and-uncontrolled | Primitive | `defaultChecked={true}` passed, no `checked`/`onCheckedChange` | Primitive renders checked initially and manages its own state internally (uncontrolled mode) |
| checkbox-023 | disabled-state | Primitive | `disabled={true}` passed to `CheckboxPrimitive.Root` | Root renders as a `<span role="checkbox">` with `aria-disabled="true"`, `data-disabled`, and `tabindex="-1"`; no opacity/cursor/pointer-events change occurs, since `disabled:opacity-50`/`disabled:pointer-events-none`/`disabled:cursor-not-allowed` never match a `<span>`; toggling is still blocked internally |

