
FieldValue has no configuration options beyond its props.

| Prop | Type | Required | Description |
|------|------|----------|-------------|
| `field` | `PublicField` | yes | The field to render: `key: string`, `label: string`, `type: FieldType`, `value: unknown`, `visibility: FieldVisibility`. |
| `resolveImageUrl` | `(attachmentId: string) => string \| null` | no | Turns an image attachment ID into a URL, or `null` for no image. Without it, image fields render nothing. |

The test inputs below write `value` and `label` beside `type`, as properties of the `field` object.

