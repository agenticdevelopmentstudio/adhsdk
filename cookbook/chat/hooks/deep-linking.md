
Not applicable: none of these thirteen hooks read or write `location`,
`history`, route params, or any other link-derived state. The identifiers
they do carry (conversation ID, persona ID, participant IDs) are either
caller-supplied configuration or generated locally with
`crypto.randomUUID()` inside `useChatSession`, never parsed from a URL.

