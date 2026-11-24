
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| action | closure taking no arguments and returning nothing | required | Runs when the item is chosen. |
| isEnabled | closure returning a boolean | always true | Evaluated on each validation to decide whether the item is enabled. |
| isChecked | optional closure returning a boolean | absent | When present, evaluated on each validation to set the item's checked mark. |

