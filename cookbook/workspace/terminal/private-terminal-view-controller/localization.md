
All user-facing text is a literal string in the source; none goes through a localization lookup.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (literal) | Show the private terminal | Eye label, tooltip, accessory when hidden, authentication reason base |
| (literal) | Hide the private terminal | Accessory title when revealed |
| (literal) | Click the eye to show this terminal. | Screen message, shell started |
| (literal) | Click the eye to start this private terminal. | Screen message, shell not started |
| (literal) | Open Secrets… | Options button |
| (literal) | show the private terminal | Authentication reason |
| (literal) | This pane has a running private terminal session. Removing the pane ends it. | Removal confirmation |

- **string-externalization**: Every string above is a hard-coded English literal; the source does no localization lookup and has no localization table.
