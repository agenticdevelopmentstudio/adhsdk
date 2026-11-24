
- **Radio indicator**: The native input is visually hidden by the `aws-radio__input` rule; the `aws-radio__indicator` span draws the circle, and its size, border and corner radius come from the external `aws-radio` stylesheet
- **Padding**: Fieldset padding managed by CSS classes (aws-field)
- **Font**: Uses inherited font; choice labels rendered with aws-radio__label class
- **Background**: Transparent (fieldset background managed by aws-field class)
- **Foreground/Text**: Inherited text color for labels and hints
- **Border**: Not defined in this source file; entirely owned by the `aws-field` stylesheet rule the caller supplies. No border renders unless that external CSS adds one.
- **Shadow**: None
- **Min/Max size**: No explicit constraints; layout determined by CSS classes (class names: see #requirements/css-class-hooks)

