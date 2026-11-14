
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| explanation-001 | render-paragraph | `<Explanation>Hello</Explanation>` | Renders as `<p class="aws-explanation">Hello</p>` |
| explanation-002 | apply-default-class | Any props | Rendered element contains class `aws-explanation` |
| explanation-003 | render-children | `<Explanation>Text content</Explanation>` | Text content appears inside the paragraph |
| explanation-004 | accepts-optional-classname | `<Explanation className="custom-class">Text</Explanation>` | Rendered element has both `aws-explanation` and `custom-class` |
| explanation-005 | combine-classnames | `<Explanation className="extra">Content</Explanation>` | Rendered class attribute is `"aws-explanation extra"` |
| explanation-006 | filter-falsy-classnames | `<Explanation className="">Text</Explanation>` | Rendered class attribute is `"aws-explanation"` (empty string filtered out) |
| explanation-007 | render-children | `<Explanation><span>Rich</span> content</Explanation>` | React children (including JSX elements) render correctly inside paragraph |
| explanation-008 | render-paragraph | `<Explanation />` (children omitted) | Renders as `<p class="aws-explanation"></p>` |
| explanation-009 | render-paragraph | `<Explanation>{''}</Explanation>` (empty-string children) | Renders as `<p class="aws-explanation"></p>` |
| explanation-010 | filter-falsy-classnames | `<Explanation className={undefined}>Text</Explanation>` | Rendered class attribute is `"aws-explanation"` |
| explanation-011 | filter-falsy-classnames | `<Explanation className="   ">Text</Explanation>` | Rendered class attribute is `"aws-explanation    "` (whitespace-only string is truthy, so it passes through unchanged) |
| explanation-012 | combine-classnames | `<Explanation className="class1 class2">Text</Explanation>` | Rendered class attribute is `"aws-explanation class1 class2"` (internal whitespace between classes is preserved) |

