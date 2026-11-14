
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| afterId | Int? | none (caller supplies) | Exclusive lower cursor; nil starts at the first message. |
| throughId | Int? | none (caller supplies) | Inclusive upper cursor; nil runs to the newest message. |
| limit | Int | none (caller supplies) | Most messages per page, in whole transcript entries; the daemon raises a value below 1 to 1. |
| includeWorkOutput | Bool | none (caller supplies) | Whether `progress` and `thinking` lines and subagent transcripts are read. |
| agentId | String? | nil | Set only for a subagent's message. |

