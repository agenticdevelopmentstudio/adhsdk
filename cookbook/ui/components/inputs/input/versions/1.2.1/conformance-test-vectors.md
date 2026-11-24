
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| input-001 | input-type | `type="email"` | HTML input element has type="email" attribute |
| input-002 | input-type | `type="password"` | HTML input element has type="password" attribute |
| input-003 | placeholder | `placeholder="Enter name"` | Placeholder text visible when field empty, styled with `text-apt-text-dim` |
| input-004 | autofill-token | `autoComplete="email"` | Autofill token applied; password managers can detect field |
| input-005 | autofill-token | `autoComplete={undefined}` | Off-attribute set applied (`autocomplete="off"`, `data-form-type="other"`, `data-1p-ignore`, `data-lpignore`, `data-bwignore`, `data-protonpass-ignore`); password managers blocked |
| input-006 | selection-styling | Text highlighted by user | Selected text background: `apt-gold/30` (30% opaque gold) |
| input-007 | dom-prop-forwarding | `value="test"` onChange={handleChange} | value prop passed through; onChange callback fires on input |
| input-008 | field-shell-styling | Rendered on page | Field has rounded corners (8px), 1px border, and `apt-bg` background |
| input-009 | width-constraint | Within 200px container | Field width matches container (100%), does not overflow |
| input-010 | classname-merging | `className="custom-class"` | Both default classes and custom-class applied to element |
| input-011 | #states/focus | User tabs to field or clicks | Border color changes to `apt-gold`; 2px `apt-gold/25` outer ring visible around the field |
| input-012 | #states/disabled | `disabled={true}` | Opacity 50%, cursor not-allowed, no pointer events |
| input-013 | #states/invalid | `aria-invalid="true"` | Border color: `apt-red`; 2px `apt-red/25` outer ring visible around the field |

