
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| model | GmailSettingsModel | none (required) | The observed model the view reads and calls. |
| pollChoices | list of minutes | 5, 15, 30, 60 | Fixed choices for "Check for mail every". |
| windowChoices | list of days | 7, 14, 30, 90, 180, 365 | Fixed choices for "Fetch mail from the last"; fixed windows rather than a stepper because "each change re-syncs, so a day at a time is costly". |
| client form maximum width | points | 460 | Width limit of the ID and secret fields. |
| picker maximum width | points | 300 | Width limit of both pickers. |
| list minimum height | points | 120 | Minimum height of the account list. |
| content inset | points | 20 | Padding around the pane. |

