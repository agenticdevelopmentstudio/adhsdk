
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| avatar-001 | render-root-with-semantic-class | Render `<Avatar />` with no props | Rendered root element has class `adh-avatar` |
| avatar-002 | render-image-with-semantic-class | Render `<Avatar><AvatarImage src="<1x1 stub already loaded>" /></Avatar>` | Rendered image element has class `adh-avatar__image` |
| avatar-003 | render-fallback-with-semantic-class | Render `<Avatar><AvatarFallback /></Avatar>` | Rendered fallback element has class `adh-avatar__fallback` |
| avatar-004 | merge-consumer-classname | Render `<Avatar className="ring-2" />` | Rendered root element has both `adh-avatar` and `ring-2` classes |
| avatar-005 | merge-consumer-classname | Render `<Avatar><AvatarImage className="opacity-0" src="<1x1 stub already loaded>" /></Avatar>` | Rendered image element has both `adh-avatar__image` and `opacity-0` classes |
| avatar-006 | merge-consumer-classname | Render `<Avatar><AvatarFallback className="bg-muted" /></Avatar>` | Rendered fallback element has both `adh-avatar__fallback` and `bg-muted` classes |
| avatar-007 | forward-remaining-props | Render `<Avatar data-testid="a1" />` | Rendered root element carries `data-testid="a1"` |
| avatar-008 | forward-remaining-props | Render `<Avatar><AvatarImage alt="Ada Lovelace" src="<1x1 stub already loaded>" /></Avatar>` | Rendered image element carries `alt="Ada Lovelace"` |

