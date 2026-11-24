
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| create | boolean | false | Whether the create capability is allowed. Set independently of other capabilities. |
| read | boolean | false | Whether the read capability is allowed. Set independently of other capabilities. |
| update | boolean | false | Whether the update capability is allowed. Set independently of other capabilities. |
| delete | boolean | false | Whether the delete capability is allowed. Set independently of other capabilities. |

`Crud` is a plain interface with no constructor, so these "Default" values are not applied automatically. They describe the object `noAccess()` returns (all `false`) and, for `read`, the object `readOnly()` returns (`read: true`). A caller building a `Crud` object by hand must set every field explicitly.

