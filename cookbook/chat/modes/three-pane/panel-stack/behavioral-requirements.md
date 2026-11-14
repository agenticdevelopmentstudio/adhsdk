
- **render-visible-panes**: Component MUST render a DetailPane for each index in the `visibleTopicIndexes` array.
- **pass-topic-data**: Component MUST pass the topic object from the `topics` array to each rendered DetailPane.
- **pass-image-load-callback**: Component MUST pass the `onImageLoad` callback to each DetailPane instance.
- **skip-missing-topics**: Component MUST render nothing for any index in `visibleTopicIndexes` whose topic is missing from `topics` (out of bounds, negative, non-integer, or otherwise resolving to no topic); the stack itself and the panes for the other indexes still render.
- **mark-visible-state**: Component MUST pass `visible={true}` to each DetailPane it renders. Per DetailPane's `visibility-state` requirement ([adhsdk.ingredient.chat.modes.three-pane.detail-pane](cookbook:292f17e2-1df8-4126-a26c-4160e8e88708)), `visible` controls whether the child applies `pc-pane-visible` or `pc-pane-hidden` while staying mounted either way. PanelStack has no model for a hidden-but-mounted pane: an index is either present in `visibleTopicIndexes` (its DetailPane renders with `visible={true}`) or absent (no DetailPane exists for it at all) — `visible={false}` never occurs here.
- **use-message-index-as-key**: Component MUST use the topic's `messageIndex` as the React key when rendering each DetailPane. This preserves each DetailPane's instance identity across reorders of `visibleTopicIndexes` as long as the indexes it lists resolve to distinct `messageIndex` values. Distinct indexes are a precondition the caller MUST meet; see the **duplicate-indexes** edge case.
- **forward-ref**: Component MUST expose the root div element to its parent through a ref.
- **apply-class-name**: Component MUST apply the CSS class name `pc-panel-stack` to the root div.

