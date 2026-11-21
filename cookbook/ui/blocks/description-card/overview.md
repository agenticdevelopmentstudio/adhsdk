
`DescriptionCard` in `@adh-sdk/ui` shows a title and a description in a `Card`. `ui` has no markdown dependency, so the description is rendered by the `renderMarkdown` function the caller passes; without one it is plain text with its line breaks kept. When both title and description are empty the block renders nothing.
