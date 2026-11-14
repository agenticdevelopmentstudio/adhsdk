
`OversightScript` is the configuration record of AI oversight: a trigger (a boolean predicate over one live session, optionally confirmed by an LLM) and a response (the finding to record and the action a human can dispatch on it). The shipped "compact" script is the first one; users create their own. The types live in the shared package so the daemon (evaluation and storage), the app (the editor), HTTP and XPC all speak one shape.

The file holds the script value and its parts (`ScriptTrigger`, `LLMConfirmation`, `ScriptResponse`), the predicate tree (`ScriptPredicate` with `ConditionField` and `ConditionOperator`), the action (`ScriptAction`), and one constant namespace, `OversightProviderSelection`, with the provider-selection sentinel. It defines shapes and their wire spelling only. Predicate evaluation, reason rendering, save-time validation, storage, built-in upgrade and the LLM call belong to the daemon.

