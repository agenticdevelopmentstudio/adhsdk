
- **placeholder-token**: `SummaryDefaults.maxWordsPlaceholder` MUST be the literal text `{maxWords}`.
- **placeholder-substitution-site**: A consumer MUST substitute the effective max-word count for each occurrence of the placeholder in the prompt; `SummaryPrefs.resolvedPrompt` is the source's one substitution.
- **placeholder-dropped**: A user-edited prompt that drops the placeholder MUST keep its wording unchanged, so the model is not told the word cap while the cap still applies to the reply; the source's comment says an explicit prompt beats "a hidden sentence appended behind the user's back".
- **default-prompt**: `SummaryDefaults.prompt` MUST be the system prompt template that opens `You write a title of at most {maxWords} words for a coding session.` and carries the placeholder once, in that first sentence.
- **default-prompt-instructions**: The default prompt MUST tell the model to start with a verb ending in -ing, to be brief and plain, never to ask questions, explain or say it lacks context, to guess from what is there when the activity is unclear, and to output only the short phrase.
- **default-prompt-examples**: The default prompt MUST give four examples: `fixing the sessions window UI`, `adding keyboard shortcuts`, `cleaning up old code` and `exploring the codebase`.
- **default-prompt-verbatim**: `SummaryDefaults.prompt` MUST be exactly this text, with `{maxWords}` as the placeholder and no newline:

  ```text
  You write a title of at most {maxWords} words for a coding session. Start with a verb ending in -ing. Be brief and plain — no jargon, no technical detail, no explanation. NEVER ask questions. NEVER explain. NEVER say you lack context. If the activity is unclear, make your best guess from what is there. Output ONLY the short phrase and nothing else. Examples: "fixing the sessions window UI", "adding keyboard shortcuts", "cleaning up old code", "exploring the codebase".
  ```
- **default-prompt-single-line**: The default prompt MUST be one logical line: each source line break is a line continuation, so the string holds no newline.
- **default-max-words**: `SummaryDefaults.maxWords` MUST be 8.
- **default-activity-lines**: `SummaryDefaults.activityLines` MUST be 60, the count of the session's most recent events that go into the prompt.
- **default-detail-chars**: `SummaryDefaults.detailChars` MUST be 120, the per-event detail cap inside the prompt.
- **default-interval-minutes**: `SummaryDefaults.intervalMinutes` MUST be 5, how often the daemon looks for sessions that still need a summary.
- **default-max-per-run**: `SummaryDefaults.maxPerRun` MUST be 5, the sessions one pass summarizes.
- **default-timeout-seconds**: `SummaryDefaults.timeoutSeconds` MUST be 60, the per-completion budget.
- **max-words-double-duty**: The max-word cap MUST be told to the model through the placeholder and enforced on the reply, because the source states a small local model routinely overruns it.
- **character-cap-formula**: `characterCap(maxWords:)` MUST return the larger of 80 and ten times `maxWords`.
- **character-cap-purpose**: The character cap MUST serve as the belt-and-braces limit on a title that is one enormous word, such as a pasted path or a wall of punctuation.
- **character-cap-shared-with-purge**: The startup purge of overlong summaries MUST use the same `characterCap(maxWords:)` value as the summarizer; a purge threshold below the cap wipes titles the summarizer just wrote and re-queues them forever.
- **limit-max-words**: `SummaryLimits.maxWords` MUST be the closed range 4 through 20.
- **limit-activity-lines**: `SummaryLimits.activityLines` MUST be the closed range 10 through 400.
- **limit-detail-chars**: `SummaryLimits.detailChars` MUST be the closed range 40 through 500.
- **limit-interval-minutes**: `SummaryLimits.intervalMinutes` MUST be the closed range 1 through 240.
- **limit-max-per-run**: `SummaryLimits.maxPerRun` MUST be the closed range 1 through 50.
- **limit-timeout-seconds**: `SummaryLimits.timeoutSeconds` MUST be the closed range 10 through 600.
- **defaults-inside-limits**: Each numeric default MUST lie inside its range, so a reset value is never clamped.
- **clamp-contract**: `clamp(_:to:)` MUST return the range's lower bound for a value below it, its upper bound for a value above it, and the value itself otherwise.
- **clamp-both-sides**: The app and the daemon MUST both clamp through `SummaryLimits`, so an out-of-range value from an older app or a hand-rolled HTTP POST lands on a sane number instead of wedging the summarizer.
- **settings-key-names**: `SummarySettingsKeys` MUST name seven keys: `prompt` as `ai_summary_prompt`, `maxWords` as `ai_summary_max_words`, `activityLines` as `ai_summary_activity_lines`, `detailChars` as `ai_summary_detail_chars`, `intervalMinutes` as `ai_summary_interval_minutes`, `maxPerRun` as `ai_summary_max_per_run` and `timeoutSeconds` as `ai_summary_timeout_seconds`.
- **settings-key-home**: The keys MUST live in this file so the wire contract and the storage contract are read from one place.
- **daemon-fallback**: A daemon MUST fall back to `SummaryDefaults` for any knob never pushed; `SummaryPrefs` does so for a missing, blank (prompt) or unparseable (number) stored value.
- **type-shape**: `SummaryDefaults`, `SummaryLimits` and `SummarySettingsKeys` MUST be caseless `public enum` namespaces that cannot be instantiated.
- **no-persistence-here**: These types MUST NOT read or write the settings table themselves; clamping a stored or pushed value is the caller's act.

