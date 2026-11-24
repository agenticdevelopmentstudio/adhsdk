
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `PartnerJob.id` | string | none (required) | Identity; also the key in the store and the name used in job files and skills |
| `PartnerJob.name` | string | none (required) | Display name, also used in the system prompt heading for the job |
| `PartnerJob.isEnabled` | bool | none (required) | Whether the job's guidelines and timer are active |
| `PartnerJob.scheduleSeconds` | optional int | nil | Timer interval in seconds; nil or non-positive means no timer |
| `PartnerJob.guidelines` | string | none (required) | Instructions the partner follows for this job |
| `PartnerJob.steps` | array of `PartnerJobStep` | none (required) | Ordered steps to type |
| `PartnerJob.isBuiltIn` | bool | false | Marks a job the app seeds |
| `PartnerJobStep.name` | string | none (required) | Step label |
| `PartnerJobStep.environment` | `terminal` or `claude` | none (required) | Where the command is typed |
| `PartnerJobStep.command` | string | none (required) | Text to type; may carry brace-wrapped placeholders |
| `PartnerJobStep.condition` | string | none (required) | When it is the right moment; empty for none |

