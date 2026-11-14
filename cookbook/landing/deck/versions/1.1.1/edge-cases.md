
- **Empty children** (`#requirements/render-children`): Deck MUST render successfully when its child content is empty, null, or undefined.
- **Falsy style-hook values** (`#requirements/merges-style-hook`): Deck MUST filter out falsy style-hook values (null, undefined, false, empty string) before combining them.
- **Multiple class tokens in the style hook** (`#requirements/merges-style-hook`): When the consumer's style hook contains multiple space-separated tokens, Deck MUST preserve all of them when merging with its own base style hook.
- **No consumer style hook supplied** (`#requirements/merges-style-hook`): Deck MUST render with only its own base style hook when the consumer supplies none.

