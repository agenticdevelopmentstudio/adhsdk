
- **Null/empty `className`**: `Avatar`, `AvatarImage`, and `AvatarFallback` MUST still render when `className` is omitted (`undefined`), passing `undefined` as the second argument to `cn`; the wrapper performs no validation of `className` before doing so.
- **No other props supplied**: `Avatar` MUST render correctly when called
  with no props beyond (or including) `className`, since `{...props}` is
  spread unconditionally and the wrapper performs no required-prop checking
  of its own. `AvatarImage` and `AvatarFallback` MUST likewise render
  correctly with no props beyond `className`, but only when nested inside
  `<Avatar>`: both delegate to a Base UI part that reads `Avatar`'s root
  context, so either one MUST throw ("Base UI: AvatarRootContext is
  missing. Avatar parts must be placed within `<Avatar.Root>`.") when
  rendered standalone, regardless of what other props it receives.
- **Boundary values**: Not applicable: Component defines no numeric, length, or size-constrained props of its own (e.g. no `size`, `min`, `max`); any such constraints belong to the underlying Base UI `Avatar.Root`/`Image`/`Fallback` API.
- **Concurrent access**: Not applicable: `Avatar`, `AvatarImage`, and `AvatarFallback` are stateless functional components with no internal state, refs, or module-level mutable data; each render is an independent, pure function call.
- **Error states**: `AvatarImage` MUST unmount when its underlying `<img>` fails to load, which is what reveals `AvatarFallback`; this load-failure-to-fallback handoff is Base UI's `Avatar.Image`/`Avatar.Fallback` behavior (`@base-ui/react/avatar`), not logic this wrapper adds.
- **Offline or disconnected state**: `AvatarImage` MUST fall back the same way whether a load failure is caused by an offline network or any other image-load error, because Base UI's Avatar has no separate retry or timeout path for network failures — a failed load unmounts `Avatar.Image` and reveals `Avatar.Fallback` exactly as in Error states above.

