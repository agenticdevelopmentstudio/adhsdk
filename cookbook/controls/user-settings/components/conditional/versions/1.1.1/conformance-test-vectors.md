
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| conditional-001 | render-children-when-true | `when={true}`, `children="Hello"`, `fallback="Goodbye"` | Renders "Hello" |
| conditional-002 | render-fallback-when-false | `when={false}`, `children="Hello"`, `fallback="Goodbye"` | Renders "Goodbye" |
| conditional-003 | fallback-defaults-to-null | `when={false}`, `children="Hello"` (no fallback prop) | Renders nothing (null) |
| conditional-004 | inactive-branch-not-mounted | Render with `when={true}`, `children={<Stateful />}` (a component holding local state); re-render with `when={false}` | The `fallback` branch renders; the previous `children` branch is unmounted and its state is discarded |
| conditional-005 | no-wrapper-element | `when={true}`, `children=[<span>A</span>, <span>B</span>]` | Both children render without a parent wrapper |
| conditional-006 | null-children-renders-nothing | `when={true}`, `children={null}` | Renders nothing |
| conditional-007 | falsy-children-renders-value | `when={true}`, `children={0}` | Renders "0" |
| conditional-008 | mixed-children-render-in-order | `when={true}`, `children={["A", <span>B</span>, <>C</>]}` | Renders "A", then `<span>B</span>`, then "C", in that order |

