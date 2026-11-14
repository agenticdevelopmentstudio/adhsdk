
- **render-card**: Component MUST render a Card element containing an icon, optional headline, and optional descriptive content.
- **render-icon**: Component MUST render a mouse-pointer icon (MousePointerClick from lucide-react) inside a circular container.
- **use-test-hook**: Component MUST set `data-htd-select-hint` attribute on the root container for test targeting. The `htd` prefix is the shared test-hook namespace for the whole HierarchicalTopicDetail component family (`topic-detail`, `hierarchical-topic-detail`, `hierarchical-menu-detail`); TopicSelectHint is that family's shared "nothing selected" placeholder, so it carries the same prefix rather than a bespoke one.
- **accept-custom-title**: Component MUST render the `title` prop as the headline verbatim when provided, taking precedence over computed headlines and over `selectable` — an explicit `title` still renders even when `selectable` is false.
- **compute-headline-from-noun**: Component MUST generate the headline as "Select [article] [noun]" when `noun` is provided (truthy) and `title` is not, where `article` is `"an"` when `noun`'s first character matches `/^[aeiou]/i` (case-insensitive) and `"a"` otherwise. This is a naive first-letter rule, not true English pronunciation, so it mis-genders words like "hour" and "user" — see Edge Cases.
- **compute-headline-from-list-title**: Component MUST generate the headline as "Select an item from [listTitle]" when `listTitle` is provided (truthy), `noun` is not, and `title` is not.
- **use-fallback-headline**: Component MUST generate the headline as "Select an item from the list" when none of `title`, `noun`, or `listTitle` are provided (or `noun`/`listTitle` are falsy, e.g. an empty string), and `selectable` is true.
- **append-edit-suffix**: Component MUST append " to view or edit it here." to the computed headline when `selectable` is true and no `children` are provided. This applies to every computed headline (noun-derived, listTitle-derived, and the fully generic default) equally.
- **hide-headline-when-not-selectable**: Component MUST NOT render the computed headline when `selectable` is false and no `title` is provided; an explicit `title` still renders regardless of `selectable`.
- **render-children**: Component MUST render the `children` prop as descriptive content when provided.
- **hide-children-when-not-provided**: Component MUST not render a content section when `children` are not provided.
- **center-content**: Component MUST center the card horizontally and vertically within its container.

