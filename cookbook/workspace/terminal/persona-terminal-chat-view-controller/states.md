
| State | Appearance change |
|-------|------------------|
| Default (no provider chosen) | Composer disabled; status `Choose an LLM provider in this pane's Settings` |
| Provider chosen, Connect off | Composer enabled; status `Not connected — turn on Connect to Terminal Chat in this pane's Settings` |
| Connect on, no Terminal Chat in the tab | Composer enabled; status `No Terminal Chat in this tab to connect to` |
| Ready (provider, Connect on, Terminal Chat found) | Composer enabled; status cleared |
| Pressed | Not applicable: this controller draws no control of its own; the native controls and chat view own pressed and focused appearance |
| Disabled | Composer disabled only in the no-provider state; the options controls are never disabled |
| Loading | Model picker shows the template list until a live list replaces it; no spinner is shown (a fact of the source) |

