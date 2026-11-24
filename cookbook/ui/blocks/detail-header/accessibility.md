
- **disabled-reason-in-name**: A disabled control MUST carry its reason in its accessible name (`API — This view has no API endpoint`, `About this section — No help for this view`), so a screen-reader user hears why it is unavailable.
- **tooltip-on-wrapper**: The reason MUST also be a tooltip, placed on a wrapper, because a disabled button receives no pointer events.
- **icon-decorative**: The code icon on the disabled API button MUST be hidden from assistive technology, and the text "API" carries the meaning.
- **disabled-skipped**: The disabled buttons are native disabled buttons and MUST be skipped by the Tab order.
- **claimed-controls**: A claimed control keeps whatever role and name its claimant gives it; the block adds no semantics around the slots.
- **header-landmark**: NEEDS REVIEW: Not implemented in source. The row is a plain `div` with no heading or landmark role, so assistive technology gets no region named for the header; settling it needs a decision on whether the title cell carries the heading and whether the row should be a `header` landmark.
- **touch-target-size**: NEEDS REVIEW: Not implemented in source. The disabled help button is a 16px icon in the quiet control style and the API button is the extra-small size; both disabled, but claimed controls reuse the same slot and any enabled control placed there inherits a small header. Settling it needs the rendered size of the quiet control and extra-small button at the production theme and a decision on the platform minimum for header controls.
- **contrast-ratio**: NEEDS REVIEW: Not implemented in source. The disabled controls are drawn at reduced opacity on `bg-apt-nav`; disabled controls are exempt from contrast requirements, but the enabled claimed controls are not, and whether the theme tokens meet 3:1 needs measured values.

