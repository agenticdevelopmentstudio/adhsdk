
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| retryCount | Int | 0 | Failed self-healing retries so far. |
| lastRetriedAt | String? | nil | Time of the most recent retry. |
| exhausted | Bool | false | True once `retryCount` reaches the daemon's `maxRetries`, which defaults to 3 and is raised to at least 1. |

