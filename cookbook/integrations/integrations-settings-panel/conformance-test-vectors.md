
Only the model the panel drives has tests (`GmailSettingsModelTests`); the panel has no test beside it. Vectors marked "derived" take their model-side expectation from the named test, and the panel-side expectation from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| integrations-settings-panel-001 | listing-rule, picked-in-memory, remove-enabled | Provider loaded with `configured` false and nothing picked | Sidebar has no rows; remove button disabled; no call sent to the service. |
| integrations-settings-panel-002 | listing-rule, add-gmail, auto-select, remove-enabled | Provider not configured; choose "Gmail" from the add menu | Sidebar lists one "Gmail" row, selected; remove button enabled; no call sent to the service. |
| integrations-settings-panel-003 | listing-rule, rebuild-on-change | Provider changes to `configured` true after a reload (derived from `reloadLoadsProviderAndAccounts`) | One main-queue turn later the sidebar lists the "Gmail" row and selects it. |
| integrations-settings-panel-004 | add-menu, add-menu-disabled | Gmail already listed; press `+` | A one-item menu appears under the button; "Gmail" is disabled. |
| integrations-settings-panel-005 | remove-refused-when-empty | Nothing listed; press `−` | Refusal feedback is announced; no confirmation opens; listing unchanged. |
| integrations-settings-panel-006 | remove-confirmation, remove-cancel-default | Gmail listed; press `−` | Sheet "Remove Gmail?" with action "Remove" and the stated detail; Return selects Cancel. |
| integrations-settings-panel-007 | remove-declined | Open the confirmation; press Esc | Sheet closes; Gmail still listed; no `removeProvider` call sent. |
| integrations-settings-panel-008 | remove-configured | Provider `configured` true; confirm "Remove" | The model sends the remove-provider call (derived from `removeIntegrationClearsAccounts`); listing rebuilds empty; remove button disabled. |
| integrations-settings-panel-009 | remove-unknown-as-configured | Provider not yet loaded or its load failed; Gmail picked; confirm "Remove" | The model's remove call is sent; picked state cleared; listing rebuilds empty. |
| integrations-settings-panel-010 | remove-unconfigured | Provider loaded with `configured` false; Gmail picked from `+`; confirm "Remove" | No remove call sent; the model's error message is cleared (derived from `dismissErrorClearsIt`); listing rebuilds empty. |
| integrations-settings-panel-011 | started-latest-sign-in | Two panels share one tracker; only the first starts a sign-in (derived from `onlyTheModelThatStartedTheLatestSignInClaimsIt`) | The first panel reports true; the second reports false. |
| integrations-settings-panel-012 | reload-after-sign-in | Call `reloadAfterSignIn()` after a sign-in finished | The model reloads and the listing reflects the new provider state. |
| integrations-settings-panel-013 | help-topics, search-keywords, gmail-detail-keywords | Read the help content and keywords of the panel and its Gmail detail | Two topics titled "Integrations" and "Gmail"; the panel keywords are the eight listed, the Gmail detail's are seven, without "integrations". |
| integrations-settings-panel-014 | panel-identity, sidebar-title, gmail-row, footer-controls, add-tooltip, remove-tooltip | Load the panel's view | Title and sidebar title "Integrations"; row "Gmail"; add tooltip "Add an integration"; remove tooltip "Remove the selected integration"; footer prefix `integrations.add-remove` with separator above. |

