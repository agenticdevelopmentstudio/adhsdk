
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| prompt | String | the default prompt, with `{maxWords}` | System prompt template, stored under `ai_summary_prompt`. |
| maxWords | Int | 8 (range 4 to 20) | Word cap on a title, stored under `ai_summary_max_words`. |
| activityLines | Int | 60 (range 10 to 400) | Most recent session events in the prompt, stored under `ai_summary_activity_lines`. |
| detailChars | Int | 120 (range 40 to 500) | Per-event detail cap in the prompt, stored under `ai_summary_detail_chars`. |
| intervalMinutes | Int | 5 (range 1 to 240) | Minutes between looks for sessions needing a summary, stored under `ai_summary_interval_minutes`. |
| maxPerRun | Int | 5 (range 1 to 50) | Sessions summarized per pass, stored under `ai_summary_max_per_run`. |
| timeoutSeconds | Int | 60 (range 10 to 600) | Per-completion budget in seconds, stored under `ai_summary_timeout_seconds`. |

