
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| viewport-spacer-001 | render-children | `children={<p>Content</p>}` | Component renders the paragraph element as a child |
| viewport-spacer-002 | root-element, default-class | No props provided | Root element is a `div` with `class="vp-spacer"` |
| viewport-spacer-003 | class-composition | `className="my-custom"` | Root element has `class="vp-spacer my-custom"` |
| viewport-spacer-004 | class-composition | `className="custom-a custom-b"` | Root element has `class="vp-spacer custom-a custom-b"` |
| viewport-spacer-005 | render-children | `children={null}` (or omitted) | Component renders an empty `div` with class `vp-spacer` and no error |
| viewport-spacer-006 | class-composition | `className=""` (empty string) | Root element has `class="vp-spacer"` (empty string does not add a trailing space) |
| viewport-spacer-007 | render-children | `children={<><p>A</p><span>B</span></>}` (fragment with two children) | Component renders both the paragraph and the span |
| viewport-spacer-008 | fills-remaining-space | Rendered as a child of a `.viewport-shell` flex-column container | Root element's computed style has `flex: 1 1 0` and `min-height: 0` |
| viewport-spacer-009 | assistive-tech-invisible | No props (default render) | Root element has no `role`, no `aria-label`/`aria-labelledby`, and no `tabindex` attribute |

