
Vectors 001 to 008 are asserted by the named tests. Vectors 009 onward are derived from the source and are asserted by tests whose display names carry the vector id.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-base-prompt-001 | system-prompt-prefix, system-prompt-enabled-only, system-prompt-job-section | Test `systemPromptHasHeadingForEnabledJobOnly`: jobs `General coding partner` (enabled, guidelines `Be useful.`) and `Sleeper` (disabled) | Prompt starts with `text`, contains `## Job: General coding partner\n\nBe useful.` and does not contain `## Job: Sleeper` |
| partner-base-prompt-002 | steps-line-format, steps-place-label, steps-condition | Test `systemPromptListsEachEnabledJobsStepsUnderItsHeading`: one step `open session`, environment `claude`, command `claude {dir}`, condition `the shell prompt is showing` | After the job heading: `1. open session (Claude Code prompt): ` followed by the command `claude {dir}` in backticks, and `when the shell prompt is showing` |
| partner-base-prompt-003 | steps-code-review-note | Test `onlyCodeReviewStepsSayTheyArriveFilledFromReviewStart`: the default code-reviews job enabled, and a job with id `general` enabled | The first prompt contains "arrive filled in from `partner_review_start`"; the second does not |
| partner-base-prompt-004 | base-git-rules | Test `baseTextForbidsGitOutput`: read `text` | Contains "Never pass `--output` to a git command" |
| partner-base-prompt-005 | base-tool-table, base-message-kinds, base-attention-rules | Test `baseTextNamesEveryToolAndKeyPhrases`: read `text` | Contains each of the 15 tool names and the phrases `attention item`, `tick` and `went idle` |
| partner-base-prompt-006 | base-button-messages, base-item-reply | Test `baseTextCoversButtonMessagesAndItemReplies`: read `text` | Contains `Resolved: <text>`, `Confirmed: <text>`, `carries an item id` and "close that item with `partner_attention_update`" |
| partner-base-prompt-007 | skill-name-quoting, skill-description | Test `skillDescriptionIsYAMLQuoted`: job named `Say "hi": a\b` | Markdown contains `guidelines for its Say \"hi\": a\\b job. ` |
| partner-base-prompt-008 | skill-frontmatter, skill-name, skill-description | Test `skillMarkdownHasFrontmatter`: job id `general`, name `General coding partner`, guidelines `Be useful.` | Markdown starts with `---\nname: adkitchen-partner-general\ndescription: "The ADKitchen Coding Partner's guidelines for its General coding partner job. Only for the Coding Partner, which has the partner_* tools; not for ordinary requests."\n---\n` and contains `Be useful.` |
| partner-base-prompt-009 | system-prompt-no-jobs | `systemPrompt(jobs: [])` | Equals `text` |
| partner-base-prompt-010 | system-prompt-no-jobs, system-prompt-enabled-only | `systemPrompt(jobs:)` with one disabled job | Equals `text` |
| partner-base-prompt-011 | system-prompt-job-order | Two enabled jobs `A` then `B` | `## Job: A` appears before `## Job: B` |
| partner-base-prompt-012 | steps-empty | An enabled job with `steps` empty | Its section ends with its guidelines; no `### Steps` heading appears |
| partner-base-prompt-013 | steps-condition | A step whose condition is `  \n ` (whitespace only) | The step line is `1. <name> (terminal shell): ` plus the command in backticks and nothing after it |
| partner-base-prompt-014 | steps-no-trailing-newline, steps-order-preserved | A job with two steps | Lines numbered `1.` then `2.`; the prompt does not end with a newline |
| partner-base-prompt-015 | skill-enabled-ignored | `skillMarkdown(for:)` of the same job with `isEnabled` true and false | Identical strings |
| partner-base-prompt-016 | base-sections | Read `text` | The headings `The window`, `What reaches you`, `Tools`, `Attention items`, `Sessions`, `Running a job's steps` and `Git` appear in that order |
| partner-base-prompt-017 | system-prompt-pure | Call `systemPrompt(jobs:)` twice with the same jobs | Equal strings |
| partner-base-prompt-018 | base-text-constant, base-paragraph-lines | Read `text` | Equals the exact base text, and no paragraph contains an internal line break |
| partner-base-prompt-019 | steps-heading, steps-code-review-note, steps-line-format, steps-condition, steps-no-trailing-newline | The job under "Exact steps section" | `systemPrompt(jobs:)` equals `text` followed by the exact section given there |
| partner-base-prompt-020 | skill-name-id-unchecked | `skillMarkdown(for:)` for a job with id `a b` | The frontmatter contains `name: adkitchen-partner-a b` unchanged |

