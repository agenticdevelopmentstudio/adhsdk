
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| window | window | required | The window whose panes can be picked; held weakly. |
| panes | closure returning panes | required | The panes on offer, asked again on every click. |
| onPick | callback with pane and connectable content | none | Called once, when the user picks a terminal pane. |
| onFinish | callback | none | Called once, when the panel has closed, picked or cancelled. |

