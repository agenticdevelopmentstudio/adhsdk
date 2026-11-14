
RegistryProfile has no configuration options beyond its props. All behavior is determined by the `entry` data and the optional `resolveImageUrl` and `contact` props.

| Prop | Type | Required | Description |
|------|------|----------|-------------|
| `entry` | `PublicEntry` | yes | The entry to display, already filtered by the server for the viewer. |
| `resolveImageUrl` | `(attachmentId: string) => string \| null` | no | Turns an attachment ID into a URL, or `null` for no image. Defaults to a lookup in `entry.imageUrls` that returns `null` for an unmapped ID. |
| `contact` | `ReactNode` | no | Contact affordance slot, rendered only when `entry.contactMode === 'dm'`. |

`PublicEntry` fields: `slug: string`, `displayName: string`, `summary: string`, `photoAttachmentId: string | null`, `providerType: string`, `category: string`, `keywords: string[]`, `locationText: string`, `countryCode: string`, `regionCode: string`, `geo: { lat: number; lon: number } | null`, `areaServed: Record<string, unknown>`, `deliveryMode: string`, `links: Array<{ label: string; url: string }>`, `contactMode: string` (`'dm'` or `'none'`), `languages: string[]`, `fields: PublicField[]`, `services: PublicService[]`, `imageUrls: Record<string, string>`.

`PublicField` fields: `key: string`, `label: string`, `type: FieldType`, `value: unknown`, `visibility: FieldVisibility`. `FieldVisibility` is the union `'public' | 'authenticated' | 'private'`.

