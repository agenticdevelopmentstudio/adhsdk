
Not applicable: these hooks pass caller-supplied text (message content,
ritual lines, phrase pools) directly to the caller-supplied backend or
orchestrator and to caller-supplied callbacks; none of them persists,
transmits independently, or logs that text themselves. A grep of `hooks/`
for `localStorage`/`sessionStorage`/`cookie`/`credential`/`token`/`password`
finds nothing.

