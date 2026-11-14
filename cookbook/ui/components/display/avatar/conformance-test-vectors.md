
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| avatar-001 | render-root-with-semantic-class | Render `<Avatar />` with no props | Rendered root element has class `adh-avatar` |
| avatar-002 | render-image-with-semantic-class | Render `<Avatar><AvatarImage src="https://example.test/ada.png" /></Avatar>` | Rendered image element has class `adh-avatar__image` |
| avatar-003 | render-fallback-with-semantic-class | Render `<Avatar><AvatarFallback /></Avatar>` | Rendered fallback element has class `adh-avatar__fallback` |
| avatar-004 | merge-consumer-classname | Render `<Avatar className="ring-2" />` | Rendered root element has both `adh-avatar` and `ring-2` classes |
| avatar-005 | merge-consumer-classname | Render `<Avatar><AvatarImage className="opacity-0" src="https://example.test/ada.png" /></Avatar>` | Rendered image element has both `adh-avatar__image` and `opacity-0` classes |
| avatar-006 | merge-consumer-classname | Render `<Avatar><AvatarFallback className="bg-muted" /></Avatar>` | Rendered fallback element has both `adh-avatar__fallback` and `bg-muted` classes |
| avatar-007 | forward-remaining-props | Render `<Avatar data-testid="a1" />` | Rendered root element carries `data-testid="a1"` |
| avatar-008 | forward-remaining-props | Render `<Avatar><AvatarImage alt="Ada Lovelace" src="https://example.test/ada.png" /></Avatar>` | Rendered image element carries `alt="Ada Lovelace"` || avatar-009 | forward-remaining-props | Render `<Avatar><AvatarFallback data-testid="f1">AL</AvatarFallback></Avatar>` | Rendered fallback element carries `data-testid="f1"` and contains the text `AL` |
| avatar-010 | merge-consumer-classname, #edge-cases/omitted-classname | Render `<Avatar className={undefined} />` | Rendered root element has class `adh-avatar` and no `undefined` class |
| avatar-011 | #edge-cases/no-other-props-supplied | Render `<AvatarImage src="https://example.test/ada.png" />` outside `<Avatar>` | Rendering throws |
| avatar-012 | #edge-cases/error-states | Render `<Avatar><AvatarImage src="https://example.test/ada.png" /><AvatarFallback>AL</AvatarFallback></Avatar>` with `window.Image` mocked so it fires `onerror` | No `adh-avatar__image` element is rendered and the `adh-avatar__fallback` element with text `AL` is present |

Image-loading vectors need a mocked `window.Image`: Base UI's `Avatar.Image` creates `new window.Image()` and renders only after that object fires `onload` (jsdom never loads images). For avatar-002, avatar-005 and avatar-008, mock `window.Image` so it fires `onload` as soon as `src` is set; for avatar-012, mock it so it fires `onerror`.
