
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| topics | TopicData[] | required | Array of topic objects to display; each has `title` and `messageIndex`, plus other `TopicData` fields |
| activeIndex | number | required | Zero-based index of the currently active/selected topic, supplied and owned by the parent |
| onSelectTopic | (index: number) => void | required | Callback fired when a topic button is clicked with the selected topic's index |
| visible | boolean | required | Controls visibility state; true applies "pc-pane-visible", false applies "pc-pane-hidden" |

