
- **render-input-element**: The component MUST render either an HTML `<input>` element (when `multiline` is `false` or omitted) or an HTML `<textarea>` element (when `multiline` is `true`).
- **bind-value**: The component MUST bind the `value` prop to the input element's `value` attribute.
- **call-on-change**: The component MUST invoke the `onChange` callback with the current input value (string) whenever the user types into the field.
- **render-label**: When a `label` prop is provided, the component MUST render an HTML `<label>` element with `htmlFor` attribute matching the input element's `id`.
- **generate-id**: The component MUST use an explicitly supplied `id` prop for the input element when present, and otherwise MUST generate a unique ID using React's `useId` hook and apply it to the input element.
- **accept-placeholder**: The component MUST pass the `placeholder` prop to the input element.
- **respect-disabled**: The component MUST apply the `disabled` attribute to the input element when the `disabled` prop is `true`.
- **render-hint**: When a `hint` prop is provided, the component MUST render a `<p>` element containing the hint text after the input element.
- **apply-classname**: The component MUST accept a `className` prop and append it to its root element's class list.
- **support-text-types**: The `TextField` component MUST support `type` values of `'text'`, `'email'`, `'url'`, and `'tel'`, with `'text'` as the default.
- **handle-multiline**: When `multiline` is `true`, the component MUST render a `<textarea>` element with `rows="4"` instead of an `<input>` element.
- **apply-autofill-token**: When `autoComplete` is defined and, after trimming and lowercasing, is not `'off'`, the component MUST pass the original `autoComplete` value through unchanged to the input element's `autoComplete` attribute and MUST NOT apply the autofill-prevention attributes. There is no fixed allowlist of tokens — any non-`'off'` value qualifies (e.g. `'email'`, `'tel'`, `'url'`, `'name'`).
- **prevent-autofill-default**: When `autoComplete` is `undefined`, or trims/lowercases to `'off'`, the component MUST apply autofill-prevention attributes (`autoComplete: 'off'`, `data-form-type: 'other'`, `data-1p-ignore: 'true'`, `data-lpignore: 'true'`, `data-bwignore: 'true'`, `data-protonpass-ignore: 'true'`) via the `noAutofillPropsFor` helper.
- **always-prevent-password-manager**: The `SecureTextField` component MUST always apply the same six autofill-prevention attributes via `noAutofillProps` and MUST NOT accept an `autoComplete` prop.
- **mask-password-input**: The `SecureTextField` component MUST render an `<input type="password">` to visually mask the input value on screen.
- **apply-semantic-css-classes**: The component MUST apply CSS classes to structure the component: `'aws-field'` on the root, `'aws-field--text'` for both variants, `'aws-field--secure'` additionally for `SecureTextField`, `'aws-field__label'` on the label, `'aws-field__input'` and `'aws-field__textarea'` on input/textarea respectively, and `'aws-field__hint'` on the hint paragraph.

