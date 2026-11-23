
This component *is* the privacy boundary between a page and an agent.
What crosses it: allowlisted node kinds, allowlisted attributes, sanitized
`http`/`https` addresses, and form values except passwords — each string
concealed with the pane's privacy words before it is added. What never
crosses it: markup, scripts, styles, image data or sources, hidden content,
agent-list content, password values, and — on any failure — anything at
all. It stores nothing: each result lives for one tool call or one view
refresh. The one accepted failure is over-stripping.

