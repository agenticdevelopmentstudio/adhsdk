
- **SwiftUI**: Use `Stepper(value:in:step:)` or a custom composition with `Button` + `TextField` + `HStack` layout. Bind `value` to a `@State` property; the framework handles clamping. Stepper in SwiftUI does not display the numeric value directly—pair it with a Text view or TextField if the value must be visible. For a visible value and manual increment/decrement, compose with `VStack` containing a TextField for direct input and HStack buttons for increment/decrement.

- **Compose**: Implement using `Row` with `IconButton` (decrement/increment) flanking a `TextField`. Use `value` state and `onValueChange` callback. Apply bounds checking with `coerceIn(min, max)`. Set button enabled state conditionally based on current value vs. min/max. Use `BasicTextField` or `OutlinedTextField` for the value display.

- **React/Web**: The reference implementation (`packages/web/packages/controls/src/user-settings/components/Stepper.tsx`) uses a native `<input type="number">` with `<button type="button">` elements flanking it in a flex container. Its own CSS classes are named `aws-field` / `aws-stepper`; a consuming app SHOULD follow the `{{app_prefix}}-field` / `{{app_prefix}}-stepper` naming pattern instead. A `noAutofillProps` helper prevents browser autofill on the input field. Treat the reference implementation as the behavioral contract for this recipe.

- **AppKit / UIKit**: Use `NSStepper` on macOS or `UIStepper` on iOS. Both provide increment/decrement buttons and value management. `UIStepper` does not display the numeric value by default—pair it with a UITextField or UILabel to show the current value. Configure `minimumValue`, `maximumValue`, and `stepValue` properties. Bind target-action or delegation to capture value changes.

- **WinUI 3**: Implement using `NumberBox` control with `Value`, `Minimum`, `Maximum`, and `SmallChange` (step) properties. NumberBox renders spin buttons (increment/decrement) inline with a text input by default. Set `IsEnabled` to manage the disabled state. Handle `ValueChanged` event to invoke the onChange callback. SpinButtonPlacementMode can be set to `Compact` or `Inline` to control button placement.

