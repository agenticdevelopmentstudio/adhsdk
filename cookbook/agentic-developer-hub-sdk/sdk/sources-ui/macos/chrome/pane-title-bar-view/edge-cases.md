
- **Empty title**: Setting title to empty string sets tooltip to nil. Subsequent title sets restore tooltip if title is non-empty.
- **Very long title**: Title truncates in middle; full text is preserved and is reachable via accessibility (see **truncate-title-in-middle**).
- **No accessory views**: Accessory stack is empty but present; layout remains valid with title and optional gear only.
- **Main-actor-only replacement**: `PaneTitleBarView` is `@MainActor`-isolated, so accessory-view replacement can never overlap with layout on another thread; each call to the `accessoryViews` setter runs to completion (old views removed, then new views added) before layout can observe an inconsistent state. See **replace-accessory-views-atomically**.
- **No gear view**: Accessory stack extends to 6pt trailing margin; setting gear later repositions accessory stack and activates new trailing constraint.
- **Width constraint below minimum**: When yielding width (**honor-yield-width-request**) and the container constrains the bar to a very narrow width, every subview's horizontal compression resistance is priority 1 (the lowest), so the title, accessory views, and the gear itself can all be compressed or clipped — the yield applies uniformly and does not exempt any one region.

