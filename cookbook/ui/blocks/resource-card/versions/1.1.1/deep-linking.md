
Not applicable: ResourceCard itself does not implement deep linking; it delegates navigation to the anchor or LinkComponent, which handle URLs. Parent consumers can wire routes and navigation based on the `href` prop passed to ResourceCard.

