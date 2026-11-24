
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `className` (on `Avatar`) | `string \| undefined` | `undefined` | Extra class merged with `adh-avatar` via `cn`. |
| `className` (on `AvatarImage`) | `string \| undefined` | `undefined` | Extra class merged with `adh-avatar__image` via `cn`. |
| `className` (on `AvatarFallback`) | `string \| undefined` | `undefined` | Extra class merged with `adh-avatar__fallback` via `cn`. |
| `...props` (on `Avatar`) | `AvatarPrimitive.Root.Props`, minus `className` | — | Forwarded unchanged to Base UI's `Avatar.Root`. |
| `...props` (on `AvatarImage`) | `AvatarPrimitive.Image.Props`, minus `className` | — | Forwarded unchanged to Base UI's `Avatar.Image`. |
| `...props` (on `AvatarFallback`) | `AvatarPrimitive.Fallback.Props`, minus `className` | — | Forwarded unchanged to Base UI's `Avatar.Fallback`. |

The wrapper forwards all other props to the underlying Base UI primitives unchanged. See `@base-ui/react/avatar` for the exhaustive `Avatar.Root.Props`, `Avatar.Image.Props`, and `Avatar.Fallback.Props` type definitions.

<!-- appkit-avatar -->
AppKit `AvatarView`:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` | `CGFloat` | `48` | Width and height of the circle. |
| `fetch` | `AvatarView.Fetch` | `URLSession.shared.data(from:)` | Loads a picture's bytes. |
| `content` | `AvatarContent?` | `nil` | `name`, `seed` (stable identity, e.g. an email) and `imageURL`. |

