
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

<!-- appkit-avatar -->
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| avatar-101 | appkit-picture | 200 with image bytes | picture shown. |
| avatar-102 | appkit-picture | 404 with image bytes | initials stay. |
| avatar-103 | appkit-picture | 200 with `<html>` | initials stay. |
| avatar-104 | appkit-retry | offline, then 200; view added to a window | 2 fetches, picture shown. |
| avatar-105 | appkit-retry | 200; view added to a window after loading | 1 fetch, no load in flight. |
| avatar-106 | appkit-no-url-no-fetch | content with `imageURL` nil | 0 fetches, initials shown. |
| avatar-107 | appkit-initials | name `ada lovelace byron`; name blank, seed `zed@b.c`; both empty | `AL`; `Z`; `?`. |
| avatar-108 | appkit-colour | seeds ``, `ada@x.y`, `b` | palette indices 5, 6, 1. |
| avatar-109 | appkit-side | `side` 20 | fitting size 20 × 20. |

