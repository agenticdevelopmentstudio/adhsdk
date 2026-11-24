
The only test beside the source is `PersonaTerminalChatToolsTests`
(`testThePersonaChatOffersBrowserToolsAndNamesItsPane`); the other vectors are
derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| persona-001 | tools-composite, tool-caller-is-pane-id (test `testThePersonaChatOffersBrowserToolsAndNamesItsPane`) | Build with browser tools offering `browser_list` and a pane id; list the session's tools; call `browser_list` through the session | Tool names contain `browser_list`; the recorded caller is the pane id's UUID string |
| persona-002 | tools-without-browser, tool-caller-is-pane-id | Build with no browser tools and no pane id | Tool source holds only terminal tools; tool caller is `nil` |
| persona-003 | status-no-provider | Empty state store; load the view | Composer disabled; status `Choose an LLM provider in this pane's Settings` |
| persona-004 | status-not-connected | Store a valid `configurationID`; Connect off | Composer enabled; status begins `Not connected —` |
| persona-005 | status-no-terminal-chat | Valid provider, `connected` = `1`, tab with no Terminal Chat | Status `No Terminal Chat in this tab to connect to` |
| persona-006 | status-clear-when-ready, terminal-chat-lookup | Valid provider, `connected` = `1`, tab with a Terminal Chat | Status cleared; the connected chat is that Terminal Chat's session |
| persona-007 | status-no-provider, configuration-lookup | `configurationID` names a provider deleted from Settings | Treated as no provider (composer disabled) |
| persona-008 | connect-stored-as-flag, options-connect-change | Toggle Connect on, then off | State value `1`, then the key is removed (not `0`); status re-applied each time |
| persona-009 | persona-default, persona-edited | Read persona with nothing stored; commit the default text; commit `  new  `; commit blank | Default; key removed; stored `new`; key removed |
| persona-010 | provider-chosen | Model override `x` set; choose a provider | `configurationID` stored, `model` removed, model list refilled |
| persona-011 | models-keeps-override, models-default-item | Override `m9` not in the template's models | Picker holds `Provider default (<model>)`, the template models and `m9`; `m9` selected |
| persona-012 | models-live-guards | Live fetch returns an empty list | Template list is kept |
| persona-013 | models-fetch-cancelled, teardown-cancels-and-closes | Call `paneContentWillBeDiscarded()` with a fetch in flight | Fetch cancelled; session closed |
| persona-014 | context-values, context-unresolved | Resolve a context with and without a configuration | With: values plus `model`; without: empty model and empty configuration, persona as system prompt |
| persona-015 | options-rows, options-provider-list | Call `makePaneOptionRows()` with two configured providers | Four rows; the provider picker lists `None` and the two names |
| persona-016 | plugin-load-failure-silent | Choose a provider whose plugin identifier does not load | The plugin resolver returns `nil`; status is unchanged; sending a message fails the turn with `No AI provider is configured.` |

