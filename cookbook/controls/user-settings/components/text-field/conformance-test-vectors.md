
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| text-field-001 | render-input-element, bind-value, call-on-change | `<TextField value="hello" onChange={...} multiline={false} />` | Component renders an `<input>` element with `value="hello"`. |
| text-field-002 | call-on-change | Starting from `<TextField value="hello" onChange={...} />`, the user pastes "world" at the end of the input in a single paste action. | `onChange` is invoked once, with `"helloworld"` as the argument. |
| text-field-003 | render-label, generate-id | `<TextField label="Name" value="" onChange={...} />` | Component renders `<label htmlFor="[generated-id]">Name</label>` and `<input id="[generated-id]" />`. |
| text-field-004 | accept-placeholder | `<TextField placeholder="Enter text" value="" onChange={...} />` | Component renders `<input placeholder="Enter text" />`. |
| text-field-005 | respect-disabled | `<TextField value="" onChange={...} disabled={true} />` | Component renders `<input disabled />`. |
| text-field-006 | render-hint | `<TextField value="" onChange={...} hint="Helper text" />` | Component renders `<p>Helper text</p>` after the input. |
| text-field-007 | handle-multiline | `<TextField value="" onChange={...} multiline={true} />` | Component renders `<textarea rows={4} />` instead of `<input />`. |
| text-field-008 | support-text-types | `<TextField value="" onChange={...} type="email" />` | Component renders `<input type="email" />`. |
| text-field-009 | apply-autofill-token | `<TextField value="" onChange={...} autoComplete="email" />` | Component renders `<input autoComplete="email" />` with none of `data-form-type`, `data-1p-ignore`, `data-lpignore`, `data-bwignore`, `data-protonpass-ignore` present. |
| text-field-010 | prevent-autofill-default | `<TextField value="" onChange={...} />` (no `autoComplete`) | Component renders the input with `autoComplete="off"`, `data-form-type="other"`, `data-1p-ignore="true"`, `data-lpignore="true"`, `data-bwignore="true"`, `data-protonpass-ignore="true"`. |
| text-field-011 | always-prevent-password-manager | `<SecureTextField value="" onChange={...} />` | Component renders `<input type="password" />` with the same six autofill-prevention attributes as text-field-010, and no `autoComplete` prop exists to override them. |
| text-field-012 | apply-semantic-css-classes | `<TextField value="" onChange={...} />` | Root `<div>` has class list `aws-field aws-field--text`. |
| text-field-013 | apply-semantic-css-classes | `<TextField value="" onChange={...} />` | The `<input>` element has class `aws-field__input`. |
| text-field-014 | apply-semantic-css-classes | `<SecureTextField value="" onChange={...} />` | Root `<div>` has class list `aws-field aws-field--text aws-field--secure`. |
| text-field-015 | apply-semantic-css-classes | `<SecureTextField value="" onChange={...} />` | The `<input type="password">` element has class `aws-field__input`. |
| text-field-016 | apply-classname | `<TextField value="" onChange={...} className="custom" />` | Root element's class list is `aws-field aws-field--text custom`. |
| text-field-017 | generate-id | `<TextField id="custom-id" value="" onChange={...} />` | Component renders `<input id="custom-id" />`; `useId`'s generated value is not used. |
| text-field-018 | prevent-autofill-default | `<TextField value="" onChange={...} autoComplete="off" />` | Component treats `"off"` the same as an omitted `autoComplete`: the same six autofill-prevention attributes as text-field-010 are applied. |
| text-field-019 | mask-password-input | `<SecureTextField value="" onChange={...} />` | Component renders `<input type="password" />`. |
| text-field-020 | render-label, render-hint | `<TextField label="Name" value="" onChange={...} hint="Helper text" />` | DOM order is `<label>`, then `<input>`, then the hint `<p>` — the label precedes the input and the hint follows it. |

