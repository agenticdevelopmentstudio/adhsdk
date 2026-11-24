
- **group-container**: The component MUST render both buttons inside one bordered frame, collapse button first and expand button second, with a thin vertical divider between them.
- **collapse-button**: The component MUST render a collapse-all button labelled "Collapse all lists", drawn as three overlapped left-pointing chevrons.
- **expand-button**: The component MUST render an expand-all button labelled "Expand all lists", drawn as three overlapped right-pointing chevrons.
- **collapse-enabled-flag**: The collapse button MUST be enabled when `canCollapse` is true and disabled when it is false.
- **expand-enabled-flag**: The expand button MUST be enabled when `canExpand` is true and disabled when it is false.
- **flags-independent**: Each button's enabled state MUST depend only on its own flag.
- **collapse-callback**: Activating an enabled collapse button MUST call `onCollapseAll` once with no arguments.
- **expand-callback**: Activating an enabled expand button MUST call `onExpandAll` once with no arguments.
- **disabled-inert**: A disabled button MUST NOT call its callback when activated.
- **always-present**: The component MUST render both buttons at all times and MUST NOT hide a button because it is disabled.
- **tooltip-matches-label**: Each button MUST show its label as a hover tooltip (a title), identical to its accessible name.
- **button-type**: Both buttons MUST be plain buttons that do not submit a surrounding form.
- **glyph-decorative**: The chevron glyphs and the divider MUST be hidden from assistive technology, since the label names the action.
- **group-semantics**: The frame MUST be exposed as a group named "Collapse or expand all lists".
- **hook-attribute**: The frame MUST carry the attribute `data-htd-cover-all` so a host or test can find it.
- **focus-ring**: A button that receives keyboard focus MUST show a 2px ring in the gold accent at 40% opacity, with the browser default outline removed.
- **stateless**: The component MUST hold no state of its own and MUST NOT decide when a half is enabled.

