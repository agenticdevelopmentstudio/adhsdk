
Deck is a layout wrapper component that serves as the root container for screen content in a flow-based UI. Its presence also gates the document-level layout rules (root type size, horizontal clip, and, once armed, scroll snapping); see #requirements/document-gate. It does not scroll itself — the browser document handles scrolling — so it carries no height or overflow constraints. Deck maintains internal focus without entering the tab order, allowing keyboard navigation to scroll the document instead of being trapped within the component.

