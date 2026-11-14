
- **Data collected**: None. `Avatar`, `AvatarImage`, and `AvatarFallback` perform no data collection of their own; they render whatever `src`/`children`/props a consumer supplies.
- **Storage**: None. This file contains no persistence logic.
- **Transmission**: Not applicable: Component has no transmission logic; any network requests for image loading are delegated to Base UI's `Avatar.Image` implementation.
- **Retention**: None. This file has no caching or retention logic of its own.

<!-- appkit-avatar -->
- **AppKit transmission**: `AvatarView` fetches only `imageURL`, and only when it is set; callers that must not reach the network (commit authors) pass `nil`.

