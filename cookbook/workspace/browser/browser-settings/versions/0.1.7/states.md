
| State | Appearance change |
|-------|------------------|
| Settings window scope | Every topic shows every row it holds, including "Open sites in tabs" and "Keep visits for". |
| Pane scope | "Open sites in tabs" and "Keep visits for" are absent; pane-overridable rows show the override marker when the pane overrides them. |
| Chrome pane scope | General leaves out its Media and Web Inspector groups, which only WebKit honours, as the Safari topic they came from was left out of a Chrome pane's sheet. |
| Overridden (pane scope) | The row shows the override marker and "Use Global Setting", which removes the pane's value. |
| Site Data window open | The window is modal to the app; the settings window behind it does not take input until Done closes it. |
| Site Data loading | Refresh re-reads the store; the table keeps its rows until the new answer arrives. |
| Disabled | A row whose setting cannot change in the current scope (for example "Private browsing", global-only, in a pane sheet) is disabled, as today. |
| Pressed / Focused | Not applicable — platform controls' own states. |

