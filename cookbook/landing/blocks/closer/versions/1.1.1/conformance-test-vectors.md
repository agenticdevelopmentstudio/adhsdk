
| ID | Requirement | Input | Action | Expected |
|----|-----------|----|--------|----------|
| closer-001 | render-title | `title="Get Started"`, `children=<div>form</div>` | Render component | h2 element contains text "Get Started" |
| closer-002 | render-children | `title="Call"`, `children=<button>Sign Up</button>` | Render component | Button element is rendered after the h2 |
| closer-003 | apply-lp-closer-class | `title="X"`, `children=null` | Render component | Root div has className containing "lp-closer" |
| closer-004 | merge-optional-classname | `title="X"`, `className="custom-styling"` | Render component | Root div className equals "lp-closer custom-styling" |
| closer-005 | merge-optional-classname | `title="X"`, `className=""` | Render component | Root div className equals "lp-closer" (no trailing space) |
| closer-006 | merge-optional-classname | `title="X"`, `className=undefined` | Render component | Root div className equals "lp-closer" |
| closer-007 | render-children | `title="X"`, `children=null` | Render component | Component renders without error; no content follows the h2 |
| closer-008 | render-title | `title=<span>Ready?</span>`, `children=null` | Render component | h2 element contains the rendered `<span>Ready?</span>` element |

