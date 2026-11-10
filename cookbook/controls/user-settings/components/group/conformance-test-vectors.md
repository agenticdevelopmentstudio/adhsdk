
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| group-001 | grouping-container, base-style-applied | Render with default props | Root element is `<section>` with class `aws-group` |
| group-002 | title-when-provided | `title="My Title"` | Renders `<h3 class="aws-group__title">My Title</h3>` |
| group-003 | title-when-omitted | No title prop | No h3 element present |
| group-004 | hint-when-provided | `hint="Descriptive text"` | Renders `<p class="aws-group__hint">Descriptive text</p>` |
| group-005 | hint-when-omitted | No hint prop | No `<p class="aws-group__hint">` element present |
| group-006 | children-in-body | `children="Content"` | Renders `<div class="aws-group__body">Content</div>` |
| group-007 | custom-style-accepted | `className="custom-class"` | Root element has both `aws-group` and `custom-class` |
| group-008 | empty-style-filtered | `className=""` (empty string) | Root element renders only `aws-group`, empty string filtered out |
| group-009 | title-when-provided, hint-when-provided, children-in-body | `title="Title" hint="Hint" children="Body"` | All three elements rendered in correct order: h3, p, div |
| group-010 | custom-style-accepted | `className="foo bar"` (multiple space-separated classes) | Root element renders `aws-group foo bar`; all space-separated classes preserved |
| group-011 | empty-style-filtered | `className={null}` | Root element renders only `aws-group`; `null` is filtered out, no stray whitespace or literal `"null"` |
| group-012 | children-in-body | No `children` prop | `<div class="aws-group__body">` is present and empty |

