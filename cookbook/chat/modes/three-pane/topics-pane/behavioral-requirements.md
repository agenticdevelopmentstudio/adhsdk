
- **render-header**: Component MUST render a header section displaying the text "Topics".
- **render-topic-list**: Component MUST render all topics provided in the topics array as a list of button elements.
- **display-topic-title**: Component MUST display the `title` property of each topic within its button.
- **topic-selection-callback**: Component MUST invoke `onSelectTopic(index)` when a topic button is clicked, passing the zero-based index of that topic within the `topics` array.
- **indicate-active-topic**: Component MUST visually indicate which topic is currently active by comparing its index to the `activeIndex` prop and applying an "active" class when they match.
- **respect-visibility-state**: Component MUST apply a visibility class that changes between "pc-pane-visible" and "pc-pane-hidden" based on the `visible` prop.
- **render-connector-anchor**: Component MUST render a `ConnectorAnchor` child element within each topic button, with `id` set to `topic-<messageIndex>` (the literal string `"topic-"` concatenated with the topic's `messageIndex`, e.g. `topic-5`) and `className="pc-connector-anchor-out"`.

