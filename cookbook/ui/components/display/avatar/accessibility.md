
The wrapper adds no accessibility defaults of its own — it forwards every prop unchanged — so these obligations fall on the consumer:

- **Required `alt`**: `AvatarImage` forwards `alt` unchanged to Base UI's `Avatar.Image`, which renders it on the underlying `<img>`; consumers MUST supply a meaningful `alt` value, since the wrapper performs no validation or default of its own.
- **Decorative fallback**: `AvatarFallback` forwards `children` unchanged to Base UI's `Avatar.Fallback` with no default `aria-hidden`; consumers SHOULD mark fallback content `aria-hidden="true"` when it is purely decorative (e.g., initials that duplicate a name already shown as text elsewhere), to avoid a redundant screen-reader announcement.

<!-- appkit-avatar -->
AppKit `AvatarView`: role `image`, label `Avatar for <name>`, default identifier `avatar`, which a host replaces (Accounts uses `accounts.detail.avatar`).

