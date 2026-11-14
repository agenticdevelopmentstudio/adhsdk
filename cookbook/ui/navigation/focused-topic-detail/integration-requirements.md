
- **focused-state-from-known-id**: The block MUST treat the frame as focused only when `focusedId` is non-null and matches the `id` of an entry in `items`.
- **unknown-id-falls-back-to-all**: A `focusedId` that is null, or names no entry in `items` (for example the focused item was removed), MUST show the All view and MUST NOT show a half-focused frame.
- **topics-dim-when-unfocused**: While unfocused, the block MUST pass every topic to `TopicDetail` with `disabled` set, and while focused it MUST keep each topic's own `disabled` value.
- **selection-follows-focus**: The block MUST pass `activeTopicId` as the rail's `selectedId` only when focused, and null when unfocused.
- **selector-in-rail-slot**: The block MUST render a `PopupMenu` as the rail slot, fed the same `items`, with `focusedId` as its selection, `onFocus` as its select callback, and `popupAriaLabel` as its accessible name.
- **selector-bar-when-unfocused**: The block MUST set `railSlotActive` when unfocused so the gold selection bar sits on the selector row.
- **popup-new-entry-optional**: The selector SHOULD offer a New entry only when the consumer passes `onNew`, labelled by `newLabel`.
- **all-choice-clears-focus**: Choosing All in the selector MUST call `onFocus(null)`; choosing an item MUST call `onFocus` with its id.
- **pane-edge-to-edge**: The block MUST pass `panePadding={false}` so consumer content spans the full pane; the block's own header and card rows carry their own inset.
- **focused-header-derived**: When focused with no explicit `title`, `nameSuffix` set, and an active topic found in `topics`, the header MUST read "{topic label} ({item label} {nameSuffix})".
- **focused-header-override**: An explicit `title` MUST take precedence over the derived header.
- **focused-header-omitted**: When focused and neither an explicit `title` nor a derivable one exists, the block MUST omit the header row entirely.
- **focused-pane-remounts**: The focused content MUST be keyed by `focusedId`, so switching focus remounts `children` with fresh state.
- **all-header**: The All view MUST show a header titled `allTitle` (default "All items") with `allHelp`.
- **all-cards**: The All view MUST render one `ResourceCard` per item, with the item's `label` as title, `sublabel` as identifier, `description` and `meta`, and a click that calls `onFocus` with that item's id.
- **all-empty-copy**: When `items` is empty the All view MUST show `allEmptyLabel` (default "Nothing here yet.") in place of the grid.
- **headers-hoisted**: Both headers MUST be rendered with `paneTitle` so a host that hoists the pane title takes them over.
- **card-hover-gold**: The cards SHOULD hover with a gold border (`hover:border-apt-gold/60 hover:bg-apt-surface`) in place of the card default.

