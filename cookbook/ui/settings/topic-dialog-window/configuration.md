
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| windowID | String | none (required) | Keys the dialog's saved size and position |
| title | String | none (required) | The dialog title, used in the window title and toolbar title |
| panels | array of panels | none (required) | The topics, in the order shown |
| okTitle | String | "OK" | The OK button's title |
| validate | closure returning an optional String | none (required) | Asked on OK; a sentence keeps the dialog open |
| onFinish | closure taking a Bool | none (required) | Called once with true after OK, false after Cancel |
| onOK | optional closure | nil | When set, a validated OK calls it instead of finishing |
| okEnabled | Bool | true | Whether OK can be pressed |
| windowSpec | WindowSpec | 860 by 600, minimum 680 by 460, centered, persists frame | Size and position policy; an owner may replace it |

