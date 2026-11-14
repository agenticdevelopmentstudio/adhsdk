
Not applicable: The component does not implement deep-linking beyond rendering `#id` hrefs for structure. Clicking a heading link calls `preventDefault()` and smooth-scrolls to the target element instead of following the anchor, so the browser's default hash-update behavior does not run and the URL's hash does not change on click. Loading the page with a heading's `#id` already in the URL is not handled by this component.

