
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| provider-model-picker-001 | configurable-labels | Construct with labels "Summaries provider" and "Summaries model" | The rows read those labels |
| provider-model-picker-002 | leading-choices | Leading choice "Default (CLI)"; source lists configs `a`, `b` | The popup lists "Default (CLI)", `a`, `b` in that order |
| provider-model-picker-003 | provider-change-resets-model | Selection `a`; `b`'s model setting is `m9`; choose `b` | The selection setting is `b`; `b`'s model setting is `""` |
| provider-model-picker-004 | provider-change-resets-model | Selection `a`; choose `a` again | Neither setting is written |
| provider-model-picker-005 | sentinel-disables-model, provider-change-resets-model | Selection `a`; the model setting function returns none for a leading choice; choose the leading choice | The selection is the sentinel's id; no model setting is written; the model row is disabled and reads "Choose a Model" |
| provider-model-picker-006 | model-display-rule | Selected `a`; its model setting is `m2` (display "Model Two"); default `m1` | The model row reads "Model Two" |
| provider-model-picker-007 | model-display-rule | Selected `a`; its model setting is `""`; default `m1` (display "Model One") | The model row reads "Model One" |
| provider-model-picker-008 | model-display-rule | Selected `a`; model setting `""`; no default | The model row reads "Choose a Model" |
| provider-model-picker-009 | model-choice-binding | Selected `a`; the chooser reports `m3` | `a`'s model setting is `m3` |
| provider-model-picker-010 | stale-selection-kept | Daemon source that has not answered; selection `gone`; leading choice `x` | The popup shows `x`; the setting is still `gone` |
| provider-model-picker-011 | daemon-source, chooser-opens-without-catalog | Daemon source with no plugin manager; config `d1` selected; `d1`'s model setting is `qwen3` | The model row names `qwen3`, is enabled, and its chooser opens listing only `qwen3`; the source reports no default model for `d1` |
| provider-model-picker-012 | external-change-refresh | The selected provider's model setting changes to `m4` elsewhere | The model row shows `m4`'s display name |
| provider-model-picker-013 | local-source | Local source; configuration `c1` with an empty stored model and a template default `m1` | Its default model is `m1` |
| provider-model-picker-014 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |
| provider-model-picker-015 | stale-selection-kept | Authoritative source listing `a`, `b`; no leading choices; selection `gone` | The selection setting becomes `a`; `a`'s model setting is `""` |
| provider-model-picker-016 | two-rows | Construct the control | A provider popup row sits above a model picker control row |
| provider-model-picker-017 | selection-binding | Source lists `a`, `b`; selection `b` | The popup selects `b`; choosing `a` writes `a` to the selection setting |
| provider-model-picker-018 | daemon-source-async, stale-selection-kept | Daemon source not yet answered; selection `d1`; the daemon's list then arrives with `d1` | The popup rebuilds and selects `d1`; the selection setting is unchanged |
| provider-model-picker-019 | source-interface | A source listing `a`, `b`; ask for an id it does not list | The list is `a`, `b` in the source's order; the default model and chooser context for the unlisted id are none |
| provider-model-picker-020 | external-change-refresh | Selection `a`; the selection setting changes to `b` elsewhere | The popup selects `b` and the model row shows `b`'s model |
| provider-model-picker-021 | daemon-not-running | Daemon source whose list request fails | The source is not authoritative, its list is unchanged, and the stored selection is not rewritten |
| provider-model-picker-022 | configurable-labels | Construct with provider label "Summaries provider" | The popup's accessibility label is "Summaries provider" |
| provider-model-picker-023 | daemon-source | Daemon source with a plugin manager that resolves `d1`'s template; this app's model setting for `d1` is empty; template default `m1` | Its default model is `m1` |
| provider-model-picker-024 | chooser-opens-without-catalog | Local source with no plugin manager; configuration `c1` selected | The source returns no chooser context for `c1`; the model row is disabled |
