
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| columns | LogColumn[] | (required) | Array of column definitions, each with id, title, and optional width, align, defaultLevel, defaultMono, isClickable, onCellClick, onCellDoubleClick |
| lines | LogLine[] | (required) | Array of log line entries, each with id and values object keyed by column id |
| followTail | boolean | true | Automatically scroll to bottom when new lines are added |
| maxLines | number \| undefined | undefined | Maximum number of visible rows; older rows are discarded when limit is exceeded |
| emptyMessage | string | "(no events)" | Message displayed when no rows are visible |
| showHeader | boolean | true | Display column header row |
| className | string | undefined | Additional CSS class(es) to apply to the root container |
| maxHeight | string \| number \| undefined | undefined | CSS max-height value for the scrollable body container |

