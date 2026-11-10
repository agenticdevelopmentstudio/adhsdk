
- **Null or undefined entry**: Not applicable. The component requires a `PublicEntry` and will error if `entry` is null. The host is responsible for ensuring a valid entry is provided.
- **Empty entry.fields array**: See **omit-fields-section-when-empty**.
- **photoAttachmentId without URL resolution**: If `photoAttachmentId` is present but `resolveImageUrl` returns `null`, Component MUST render the profile without a photo (see **accept-null-from-resolver**).
- **All metadata fields falsy**: See **render-metadata-list-unconditionally**. The `<dl class="rp__meta">` container is still rendered; only the category, location, and languages rows inside it are omitted.
- **Link URL scheme is not restricted**: `entry.links[*].url` is rendered directly as the link's `href` with no scheme allow-list in this component; a `javascript:` or `data:` URL would render as a live, clickable link. `rel="noopener noreferrer nofollow"` and `target="_blank"` are the only safety attributes this component applies. Restricting or validating the URL scheme is the responsibility of the server that populates `entry.links`, not this presentation component.
- **Field with empty label**: Not applicable. The source assumes field labels are provided by the server; empty labels are a server data quality issue.
- **Resolver throws an error**: Not applicable. The component assumes the resolver does not throw and returns a string or null. Error handling is the host's responsibility.
- **Very long display name**: See **render-full-display-name-untruncated**.
- **Very long field values**: Component delegates to `FieldValue` component. Edge case handling is FieldValue's responsibility.
- **Concurrent updates to entry prop**: Not applicable. The component is a functional React component and does not maintain mutable state. Behavior when `entry` prop changes is React's re-render lifecycle, not a component-defined edge case.
- **contact prop changes between render cycles**: Component MUST render the new contact prop value on the next render.

