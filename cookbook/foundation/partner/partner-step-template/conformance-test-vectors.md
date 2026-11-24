
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-step-template-001 | fill-known, unknown-stays | Command `/code-review high {sha} {nope}`, values `sha` = `abc`. | `/code-review high abc {nope}` (test: fillReplacesKnownAndKeepsUnknown). |
| partner-step-template-002 | one-pass | Command `{subject} {sha}`, values `subject` = `fix {sha} {nope}`, `sha` = `abc`. | `fix {sha} {nope} abc` (test: fillIsOnePassSoAValueIsNeverReSubstituted). |
| partner-step-template-003 | terminal-quoting, claude-unquoted | A terminal step `claude --model {model}` and a Claude step `/code-review {model}`, values `model` = `opus[1m]`. | Commands become `claude --model 'opus[1m]'` and `/code-review opus[1m]` (test: aTerminalStepQuotesItsValuesAndAClaudeStepDoesNot). |
| partner-step-template-004 | plain-word-unquoted, terminal-quoting | The same terminal step with `model` = `claude-opus-5-5`. | `claude --model claude-opus-5-5`, unquoted (test: aTerminalStepQuotesItsValuesAndAClaudeStepDoesNot). |
| partner-step-template-005 | otherwise-single-quoted | `shellQuoted` of the value `it's`. | `'it'\''s'` (test: aTerminalStepQuotesItsValuesAndAClaudeStepDoesNot, line `shellQuoted("it's")`). |
| partner-step-template-006 | no-equals-no-tilde | `shellQuoted` of the value `=ls`. | `'=ls'` (test: aTerminalStepQuotesItsValuesAndAClaudeStepDoesNot). |
| partner-step-template-007 | empty-is-quoted | `shellQuoted` of the empty string. | `''` (test: PartnerStepTemplateConformanceTests). |
| partner-step-template-008 | placeholder-syntax | Command `{} {a b} {c}`, values `c` = `x`. | `{} {a b} x` (test: PartnerStepTemplateConformanceTests). |
| partner-step-template-009 | steps-keep-fields | One terminal step with `name` `open`, `condition` `when-idle` and command `echo {x}`, values `x` = `1`. | One step with `name` `open`, environment `terminal`, `condition` `when-idle` and command `echo 1` (test: PartnerStepTemplateConformanceTests). |
| partner-step-template-010 | text-between-preserved | Command `a {x} b {x} c`, values `x` = `1`. | `a 1 b 1 c` (test: PartnerStepTemplateConformanceTests). |
| partner-step-template-011 | placeholder-syntax | Command `{café}`, values `café` = `x`. | `x` (test: PartnerStepTemplateConformanceTests). |
| partner-step-template-012 | no-equals-no-tilde | `shellQuoted` of `~/x`. | `'~/x'` (test: PartnerStepTemplateConformanceTests). |
| partner-step-template-013 | terminal-quoting, claude-unquoted | One terminal step `echo {v}` and one Claude step `say {v}` in the same list, values `v` = `a b`. | Commands `echo 'a b'` and `say a b` (test: PartnerStepTemplateConformanceTests). |
| partner-step-template-014 | empty-values-unchanged | Command `x {a} {b}`, empty `values`. | `x {a} {b}` (test: PartnerStepTemplateConformanceTests). |
