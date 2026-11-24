
The component does not manage application-level states (loading, disabled, error). Link elements have inherent browser and CSS states—unvisited, visited, hover, focus, and active (pressed)—which are styled via CSS rules targeting the anchor element or its variant class selectors. The component passes these states through without modification.

