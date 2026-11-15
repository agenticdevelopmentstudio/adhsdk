
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| agent-history-tool-001 | access-three-choices, access-default-none, access-setting-key | Read the setting's cases and default with no stored value | Cases "All history", "Current tab only", "None" in that order; key `browser.agent.history_access`; default None |
| agent-history-tool-002 | access-pane-overridable | Write Current tab only into a pane's layered store | The key is not global-only; the pane store reports an override; the global value is still None |
| agent-history-tool-003 | access-row-placement | Build the Privacy and Security topic | Its History group holds a pop-up row titled "Agent can see history" with the three choices |
| agent-history-tool-004 | tool-listed, tool-arguments | List the browser tool set's tools | `browser_history` is listed with the required description and optional `pane`, `query`, `limit` |
| agent-history-tool-005 | none-refuses-with-reason | Access None; the store has 5 visits | The call fails with the exact settings sentence; the store and back/forward list are not read |
| agent-history-tool-006 | current-tab-back-forward-only | Access Current tab only; the store has 5 visits; the driven tab's back/forward list has 2 entries | The reply has exactly 2 visit lines, both from the back/forward list |
| agent-history-tool-007 | current-tab-newest-first | Access Current tab only; back/forward entries A (oldest), B, C; `query` "b" | The reply lists only B; with no query it lists C, B, A |
| agent-history-tool-008 | all-reads-store | Access All history; no query | The reply lists the store's recent visits, newest first |
| agent-history-tool-009 | all-reads-store | Access All history; `query` "docs" | The reply lists the store's search results for "docs" |
| agent-history-tool-010 | limit-default-and-cap | Access All history; 300 visits; `limit` absent, then 500 | 50 lines, then 200 |
| agent-history-tool-011 | effective-access-per-pane | Global All history; the pane overrides to None | The call fails with the settings sentence |
| agent-history-tool-012 | conceal-before-join | Privacy words {"Acme"}; a visit titled "Acme Inc" | The title appears with the stand-in, never "Acme" |
| agent-history-tool-013 | conceal-url-forms | Privacy words {"Acme Corp"}; addresses `https://x/?q=Acme%20Corp`, `https://x/?q=acme%20corp` and `https://x/?q=Acme+Corp` | No form of "Acme Corp" survives in any address |
| agent-history-tool-014 | privacy-off-unchanged, reply-lines | Agent privacy off; one visit with a title, address and time | One line holding the title, address and time exactly as stored |
| agent-history-tool-015 | closed-privacy-refuses | Agent privacy on with unreadable privacy words | The call fails with the pane's closed-privacy refusal; no visit returned |
| agent-history-tool-016 | same-access-checks | Call on a pane paused for the agent; then on a closed pane id | The paused refusal; then "pane … was closed; call browser_list" |
| agent-history-tool-017 | read-only-pane-allowed | Access All history on a read-only pane | The call succeeds; `browser_history` is in the read tool names; the store is unchanged |
| agent-history-tool-018 | reply-lines | Access All history; the store is empty | A reply saying no visits were found, not a failure |

