
Flow is a container component that wraps a page's sequential content sections — *bands* (see [adhsdk.ingredient.landing.flow.band](cookbook:e0b59d60-0a56-4bf4-85cb-fb0e58170f8e)) — establishing the structural root for that content without implementing scroll behavior itself; scrolling is delegated to the document or a parent container. The component sets `tabIndex={-1}` on its root, making it a valid programmatic focus target without adding it to the default (Tab-key) focus order.

