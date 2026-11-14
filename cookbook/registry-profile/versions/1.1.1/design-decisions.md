
- **Decision**: The component accepts an optional `resolveImageUrl` function rather than fetching images directly, falling back to the `entry.imageUrls` map when no resolver is supplied.
  **Rationale**: This allows the host to control image delivery (CDN, proxy, storybook fixtures) without the component knowing which is in use. The fallback to `entry.imageUrls` supports the common case where the backend already resolved all URLs. This design keeps the component decoupled from the host's infrastructure.
  **Approved**: pending

- **Decision**: Visibility markers are rendered inside the `<dt>` field label, not floated beside the field value.
  **Rationale**: This ensures a reader who encounters the marker has not already read a value they believed was public. The marker placement is a compromise between making the visibility constraint immediately visible and avoiding layout reflow.
  **Approved**: pending

- **Decision**: The `AUDIENCE_NOTE` Record is exhaustive on `FieldVisibility`, so adding a new visibility type to the enum without defining its marker text is a TypeScript compile error rather than a silently unmarked field.
  **Rationale**: This prevents silent rendering of unmarked fields, which is the failure mode that matters most (an unmarked field reads as public).
  **Approved**: pending

- **Decision**: The component assumes the server has already filtered out fields the viewer is not authorized to see, and renders every field in `entry.fields` with no additional client-side hiding.
  **Rationale**: Rendering only the fields in `entry.fields` is safe because the server removes inaccessible ones. The component does not hide fields in CSS or conditionally skip rendering, which would leave values in the markup where view-source tools could find them.
  **Approved**: pending

- **Decision**: The `contact` prop is a slot (a React node), not a callback function.
  **Rationale**: This gives the host full control over what contact experience is rendered (the hub messaging composer on an ADH site, no contact on an embedder's site). The slot pattern decouples the component from knowing which contact implementation is in use.
  **Approved**: pending

- **Decision**: Field labels come from `entry.fields[*].label`, which the server provides; the component does not localize these labels itself.
  **Rationale**: The server is responsible for providing labels in the viewer's language. This keeps localization out of the presentation layer.
  **Approved**: pending

- **Decision**: The display name always renders as an `<h1>`, with no prop to change the heading level.
  **Rationale**: The component assumes it is rendered as the top-level content of the page or view presenting the entry, matching how it is used today. A host that embeds it inside a page with its own `<h1>` accepts a duplicate top-level heading; the component does not currently offer a way to renumber it.
  **Approved**: pending

