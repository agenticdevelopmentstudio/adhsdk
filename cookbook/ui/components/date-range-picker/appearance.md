
- **Corner radius**: None of its own; each field's corner radius comes from the shared Input component.
- **Padding**: None on the wrapper. Each field group stacks its label above its field with a 6px gap (`gap-1.5`); the two groups sit 12px apart (`gap-3`).
- **Font**: None of its own; the label font comes from the shared Label component and the field font from the shared Input component.
- **Background**: None on the wrapper; the field background comes from the shared Input component.
- **Foreground/Text**: None of its own; text color comes from the shared Label and Input components.
- **Border**: None on the wrapper; the field border comes from the shared Input component.
- **Shadow**: None.
- **Min/Max size**: The wrapper has no fixed size. Each field is `w-auto`, so it takes the width of the browser's native date control instead of stretching to its container. The wrapper is a flex row with `flex-wrap` and `items-end`, so the groups wrap onto a second row when the width runs out and bottom-align when they share a row.

The visual form of the native date control (segments, calendar button, popup) is the browser's; the source does not style it.

