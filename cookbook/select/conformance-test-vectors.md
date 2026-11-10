
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| select-001 | native-select | Render with `value="a"`, `choices=[{value:"a",label:"A"}]`, and a no-op `onChange` | Component renders a native `<select>` element |
| select-002 | change-callback | Render with `value="a"` and `choices=[{value:"a",label:"A"},{value:"b",label:"B"}]`; user selects the option labeled "B" | `onChange` is invoked with `"b"` |
| select-003 | value-reflection | Render with `value="option2"` and three choices | The option with value `option2` is selected in the rendered select |
| select-004 | choice-rendering | Render with `choices=[{value:"a",label:"A"},{value:"b",label:"B"}]` | Two `<option>` elements are rendered |
| select-005 | choice-label-text | Render a choice with `label:"Choose Me"` | The rendered `<option>` displays text "Choose Me" |
| select-006 | disabled-choices | Render a choice with `disabled: true` | The rendered `<option>` has the `disabled` attribute |
| select-007 | disabled-control | Render with `disabled={true}` | The `<select>` element has the `disabled` attribute; user cannot interact |
| select-008 | generated-id | Render without an `id` prop | A stable ID is generated via `useId`; label's `htmlFor` matches the generated ID |
| select-009 | provided-id | Render with `id="my-select"` | The rendered select has `id="my-select"`; label's `htmlFor` is `"my-select"` |
| select-010 | label-association | Render with `label="Choose an option"` | A `<label>` element is rendered with `htmlFor` matching the select's ID |
| select-011 | wrapper-classname | Render the `aws-field` implementation with `className="custom-class"` | The wrapper div includes the class `custom-class` (the apt-token implementation instead applies `custom-class` to the `<select>` element; its wrapper div stays `class="relative"`) |
| select-012 | hint-display | Render with `hint="Select one item"` | A `<p>` element is rendered below the select displaying the hint text |
| select-013 | chevron-indicator | Render component | A chevron-down icon is displayed to the right of the select |
| select-014 | focus-style | Focus the select element via keyboard | Border changes to the accent color role, ring is visible, focus-visible styles are applied |
| select-015 | label-association | Render without a `label` prop | No `<label>` element is rendered; the select has no accessible name supplied by the component |
| select-016 | choice-rendering | Render with `choices=[]` | No `<option>` elements are rendered; the select has no selectable options |
| select-017 | hint-display | Render with `hint="Select one item"` and no `id` prop | The hint `<p>` renders as a sibling of the select; the select's `aria-describedby` attribute is not set to the hint's id (see **hint-described-by**) |
| select-018 | disabled-choices | Render a choice with `disabled: true` and attempt to select it via keyboard or pointer | The disabled `<option>` cannot be selected; native browser behavior skips it during navigation |

