
Not applicable: there is no flag-reading mechanism anywhere in these
sources. The fixed booleans `useChatSession` passes into the orchestrator's
display config (`showAvatars`, `showReadReceipts`, `showTypingIndicators`,
`allowJoining`, `allowDeparting`, `reducedMotion`) are hardcoded literals at
the call site, not values read from any flag service, environment variable,
or remote config.

