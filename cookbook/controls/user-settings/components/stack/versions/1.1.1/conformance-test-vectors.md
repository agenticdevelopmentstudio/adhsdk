
| ID | Requirements | Input | Expected |
|----|----|----|----|
| stack-001 | render-children | VStack with two child divs | Both child elements rendered in the DOM |
| stack-002 | apply-gap-prop (number) | VStack with `gap={16}` | Inline style has `gap: "16px"` |
| stack-003 | apply-gap-prop (string) | VStack with `gap="1rem"` | Inline style has `gap: "1rem"` |
| stack-004 | gap-omitted-when-unset | VStack with no `gap` prop | The inline style has no `gap` declaration |
| stack-005 | apply-align | HStack with `align="center"` | Inline style has `alignItems: "center"` |
| stack-006 | apply-justify | VStack with `justify="space-between"` | Inline style has `justifyContent: "space-between"` |
| stack-007 | apply-inline-styles | VStack with `style={{ padding: '10px' }}` | Inline styles merged; rendered element includes `padding: 10px` |
| stack-008 | apply-class-names (VStack) | VStack with `className="custom"` | Root element has classes: `aws-stack aws-stack--v custom` |
| stack-009 | apply-class-names (HStack) | HStack with `className="custom"` | Root element has classes: `aws-stack aws-stack--h custom` |
| stack-010 | render-non-semantic-div | Both VStack and HStack | Root element is a `<div>` tag with no `role` or landmark attribute |
| stack-011 | render-children (undefined children) | VStack with `children={undefined}` | Root `<div>` renders with the layout classes and no child nodes |
| stack-012 | render-children (empty array) | VStack with `children={[]}` | Root `<div>` renders with the layout classes and no child nodes |
| stack-013 | apply-gap-prop (zero, number) | VStack with `gap={0}` | Inline style has `gap: "0px"` |
| stack-014 | apply-gap-prop (zero, string) | VStack with `gap="0"` | Inline style has `gap: "0"` |
| stack-015 | apply-inline-styles (conflicting style) | VStack with `gap={8}`, `align="center"`, `style={{ gap: '2rem', alignItems: 'flex-start' }}` | Inline style has `gap: "2rem"` and `alignItems: "flex-start"` |
| stack-016 | apply-class-names (empty className) | VStack with `className=""` | Class attribute is `"aws-stack aws-stack--v"` with no empty or extra whitespace tokens |
| stack-017 | no-rest-prop-forwarding | VStack rendered with an unsupported prop forced onto it (e.g. `{ id: 'x' } as any`) | Root element has no `id` attribute |

