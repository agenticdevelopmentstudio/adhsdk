
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `topics` | `TopicData[]` | Required | Array of topic objects to be rendered. Each topic is passed to a DetailPane component; the `TopicData` shape is the Topic data model defined by [adhsdk.ingredient.chat.modes.three-pane.detail-pane](cookbook:292f17e2-1df8-4126-a26c-4160e8e88708). |
| `visibleTopicIndexes` | `number[]` | Required | Array of indexes into the `topics` array indicating which topics should be rendered. |
| `onImageLoad` | `() => void` | Required | Callback function invoked when images in DetailPane components complete loading. |
| `ref` | `React.Ref<HTMLDivElement>` | Optional | Ref object forwarded to the root div element. |

