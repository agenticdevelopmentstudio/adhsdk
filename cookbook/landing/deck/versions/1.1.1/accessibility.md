
- **Focus management** (`#requirements/focusable-not-tabbable`): A click inside Deck focuses it (or a descendant), which keeps it out of the tab order; from there, arrow keys and Page Down scroll the document rather than being trapped inside Deck.
- **No semantic role**: Deck is a structural container with no accessible role. Its root element must not be changed in a way that introduces an unintended semantic role.
- **Not a landmark** (`#requirements/not-a-landmark`): Deck is not a landmark element. The page's `<main>` landmark, if present, MUST be provided by the host shell outside Deck to avoid nested main elements.

