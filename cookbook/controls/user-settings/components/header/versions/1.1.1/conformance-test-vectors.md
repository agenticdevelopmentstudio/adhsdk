
| ID | Requirements | Input | Expected |
|-------|-------------|-------|----------|
| header-001 | h2-element | Render `<Header>Test</Header>` | DOM contains `<h2>...</h2>` element. |
| header-002 | default-class | Render `<Header>Test</Header>` | Rendered `<h2>` has `aws-header` class. |
| header-003 | class-composition, classname-prop | Render `<Header className="custom">Test</Header>` | Rendered `<h2>` has both `aws-header` and `custom` classes. |
| header-004 | children-content | Render `<Header><span>Child</span></Header>` | Rendered `<h2>` contains the child element. |
| header-005 | class-composition | Render `<Header className={undefined}>Test</Header>` | Rendered `<h2>` has only `aws-header` class; `undefined` is filtered out. |
| header-006 | class-composition | Render `<Header className="">Test</Header>` | Rendered `<h2>` has only `aws-header` class; empty string is filtered out. |

