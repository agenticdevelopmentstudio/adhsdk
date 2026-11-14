
`OversightScript` is the configuration record of AI oversight: a trigger (a boolean predicate over one live session, optionally confirmed by an LLM) and a response (the finding to record and the action a human can dispatch on it). The shipped "compact" script is the first one; users create their own. The types live in the shared package so the daemon (evaluation and storage), the app (the editor), HTTP and XPC all speak one shape.

The file holds the script value and its parts (`ScriptTrigger`, `LLMConfirmation`, `ScriptResponse`), the predicate tree (`ScriptPredicate` with `ConditionField` and `ConditionOperator`), the action (`ScriptAction`), and one constant namespace, `OversightProviderSelection`, with the provider-selection sentinel. It defines shapes and their wire spelling only. Predicate evaluation, reason rendering, save-time validation, storage, built-in upgrade and the LLM call belong to the daemon.

**Documented semantics.** These meanings come from the source's doc comments. The daemon enforces or applies them; the DTO only carries the values, so a DTO conformance test cannot check them.

- A script's `id` is a stable identifier: a slug for a built-in (example in source: `"compact"`) and a UUID string for a user script. It doubles as the `observer` namespace of the findings the script produces ([adhsdk.ingredient.foundation.stenographer.oversight-finding-dto](cookbook:7d2280c6-ae67-4ecc-9aae-dbee574b1eab)).
- `builtIn` means the script is shipped with the daemon: upgradeable, resettable and not deletable.
- `version` is the version of the shipped definition, bumped in code when a built-in's definition improves so upgrades can refresh unmodified rows.
- LLM confirmation is itself gated by the daemon's `oversight_llm_enabled` switch; `ScriptTrigger` carries no such switch.
- The confirmation reply contract is one line: `"<ACTKEYWORD>: reason"` to act, or `"WAIT: reason"` to skip this tick. The DTO declares the contract and does not parse replies.
- Numeric condition fields compare the condition's value parsed as a number; string fields support `eq`, `ne` and `contains`. The evaluator fails closed (false) for an ordering operator on a string field and for `contains` on a numeric field.
- `tokens_in_context` is derived: `context_used_pct` times `context_window_size` divided by 100.
- The type-discriminated action format is documented to accommodate future actions (notify, run-command) without a shape change; this version knows only `inject` and `none`.
- Injected text is typed into the session's terminal and is human-approved through the existing safety gate; the DTO does not send text anywhere.

The struct keys use the stenographer wire coders ([adhsdk.ingredient.foundation.stenographer.stenographer-wire](cookbook:e8286557-84ee-4f45-b78c-f1d184c51a37)). The daemon routes that serve scripts are specified by the stenographer daemon service ([adhsdk.ingredient.foundation.stenographer.stenographer-daemon-service](cookbook:96f73261-cf32-42cc-92f3-f8b58542382a)).
