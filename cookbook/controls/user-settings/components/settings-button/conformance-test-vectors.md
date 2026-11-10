
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| settings-button-001 | render-as-button | No props | Renders `<button>` element in DOM |
| settings-button-002 | default-variant | No variant prop | CSS class `aws-button--primary` is present |
| settings-button-003 | default-type | No type prop | Rendered button has `type="button"` |
| settings-button-004 | apply-base-class | No props | CSS class `aws-button` is present |
| settings-button-005 | apply-variant-class | variant="secondary" | CSS class `aws-button--secondary` is present |
| settings-button-006 | merge-classname | className="custom-class", variant="primary" | Rendered button has classes `aws-button aws-button--primary custom-class` |
| settings-button-007 | support-children | children="Click me" | Rendered button contains text content "Click me" |
| settings-button-008 | support-children | children={<span>React element</span>} | Rendered button contains the React element as child |
| settings-button-009 | accept-html-attributes | onClick handler, disabled={true} | onClick handler is attached and disabled attribute is applied |
| settings-button-010 | accept-html-attributes | aria-label="Settings" | aria-label attribute is applied to button element |
| settings-button-011 | merge-classname | No className, variant="primary" | Rendered button has classes `aws-button aws-button--primary` (no extra spaces) |
| settings-button-012 | closed-variant-set | `variant="invalid"` (type-level, uncast) | TypeScript compilation fails; `'invalid'` is not assignable to type `SettingsButtonVariant \| undefined` (a cast — `variant={'invalid' as SettingsButtonVariant}` — compiles instead, since the literal widens to `string` before the assertion and an assertion only requires comparability, so a cast must not be used as this negative check) |
| settings-button-013 | default-type | type="submit" | Rendered button has `type="submit"` (default overridden) |
| settings-button-014 | merge-classname | className="", variant="primary" | Rendered button has classes `aws-button aws-button--primary` (empty string filtered out, no extra spaces) |

