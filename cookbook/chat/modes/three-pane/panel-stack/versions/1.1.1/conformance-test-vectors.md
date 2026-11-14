
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| panel-stack-001 | render-visible-panes | `topics=[{messageIndex: 0}, {messageIndex: 1}]`, `visibleTopicIndexes=[0, 1]` | Two DetailPane components rendered in order |
| panel-stack-002 | pass-topic-data | `topics=[{messageIndex: 5, title: "Test"}]`, `visibleTopicIndexes=[0]` | DetailPane receives topic prop with messageIndex: 5 and title: "Test" |
| panel-stack-003 | pass-image-load-callback | `onImageLoad={mockFn}`, any visible panes | Each DetailPane receives onImageLoad callback |
| panel-stack-004 | skip-missing-topics | `topics=[{messageIndex: 0}]`, `visibleTopicIndexes=[0, 5, 10]` | Only first DetailPane renders; indexes 5 and 10 render nothing |
| panel-stack-005 | use-message-index-as-key | `topics=[{messageIndex: 3}, {messageIndex: 7}]`; render with `visibleTopicIndexes=[0, 1]` and capture the DOM node of the DetailPane whose topic has `messageIndex: 7`; then re-render with `visibleTopicIndexes=[1, 0]` (same topics) | The DetailPane whose topic has `messageIndex: 7` is the same DOM node instance (`===`) before and after the reorder, confirming instance identity follows `messageIndex` rather than array position |
| panel-stack-006 | forward-ref | forwardRef attached to component | Ref resolves to root div element |
| panel-stack-007 | apply-class-name | any valid props | Root div has className `pc-panel-stack` |
| panel-stack-008 | skip-missing-topics | `topics=[{messageIndex: 0}]`, `visibleTopicIndexes=[5]` | Component renders empty div (no DetailPane rendered) |
| panel-stack-009 | mark-visible-state | `topics=[{messageIndex: 0}]`, `visibleTopicIndexes=[0]` | Rendered DetailPane receives `visible={true}` |

