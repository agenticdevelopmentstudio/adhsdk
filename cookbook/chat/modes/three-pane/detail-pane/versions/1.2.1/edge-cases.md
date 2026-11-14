
- **Null topic with visible=true**: The pane renders with visibility class applied but no content to display. Expected: header "Details" renders; content area is empty.
- **Empty arrays**: When `topic.images` or `topic.links` are empty arrays (length=0), those sections do not render. Expected: only the title and description render if present.
- **Missing optional fields**: If topic lacks a description (field undefined or empty) or has empty arrays for images/links, those sections are conditionally omitted. Expected: only available fields render.
- **Image load failure**: If an image fails to load, the pane does not render an error state. Expected: broken-image placeholder behavior is left entirely to the platform's default image-failure rendering; the pane exposes no error callback — only `onImageLoad` exists, and it fires on successful loads only.
- **Concurrent image loads**: When multiple images are present and load asynchronously, `onImageLoad` callback fires for each image's load event. Expected: callback invoked once per image.
- **Null ref forwarding**: If the ref prop is not provided or is null, the component still renders and functions normally. Expected: no error; optional ref is handled by React.forwardRef.
- **Focus held inside a hidden pane**: If a link inside the pane holds focus when `visible` flips to false, the component leaves focus on that link. Expected: focus is unchanged (MUST, per focus-untouched); whether the link remains reachable by keyboard depends entirely on how `pc-pane-hidden` is styled (see Accessibility).
- **Topic replaced while hidden**: If `topic` changes while `visible` is false, the pane re-renders the new topic immediately, because its content is never unmounted. Expected: on the next show the pane already displays the new topic, with no intermediate empty state (MUST, per content-mounted-when-hidden).
- **No topic (anchor omitted)**: When `topic` is null, the pane renders no ConnectorAnchor at all — the anchor lives inside the `topic &&` block, so it doesn't exist while there's no topic (see Null topic with visible=true). Expected: no element carries a `data-connector-anchor` attribute; only the header renders.

