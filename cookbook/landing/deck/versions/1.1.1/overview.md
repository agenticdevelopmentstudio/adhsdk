
Deck is a layout wrapper component that serves as the root container for screen content in a flow-based UI. It does not scroll itself — the browser document handles scrolling — so it carries no height or overflow constraints. Deck is always a `<div>` element with the class `lp-deck` and maintains internal focus without entering the tab order, allowing keyboard navigation to scroll the document instead of being trapped within the component.

