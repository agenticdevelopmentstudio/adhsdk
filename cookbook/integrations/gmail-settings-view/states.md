
| State | Appearance change |
|-------|------------------|
| Default | Both sections shown; controls enabled as the model allows. |
| Loading (before first load) | The OAuth text reads "Checking for an OAuth client…"; no current-value grid; accounts empty. |
| No client imported | Instructional OAuth text; button titles "Save Client" and "Import Client JSON…"; Add Account disabled; caption "Add the OAuth client above before adding an account." |
| Client imported | Explanatory OAuth text; current client ID and masked secret grid; button titles "Replace Client" and "Replace from JSON…"; Add Account enabled. |
| Client imported with accounts | As above plus the caption "Accounts signed in with a replaced client need Reconnect." |
| Busy | Save Client, Import, Add Account, Remove, Reconnect and Sync Now are disabled; toggles, pickers, Cancel and Show Error stay enabled. |
| Draft incomplete | Save Client disabled while either field is empty after trimming whitespace. |
| Signing in | Spinner, "Waiting for Google sign-in in your browser…" and Cancel appear beside Add Account and Remove. |
| No selected account | Remove disabled; per-account controls absent. |
| Account status active | Badge "Connected"; Sync Now only. |
| Account status pending | Badge "Pending"; Sync Now only. |
| Account status error | Badge "Error"; Reconnect and Sync Now; Show Error when the account has a last error. |
| Account status revoked | Badge "Reconnect needed"; Reconnect and Sync Now. |
| Never synced | Row caption "Never synced". |
| Synced | Row caption "Last synced <relative time>", for example "Last synced 2 hours ago". |
| Error alert showing | A warning alert, as a sheet on the key window when there is one. |

Not applicable: the view has no pressed, hover or focused styling of its own; those come from the standard controls it composes.

