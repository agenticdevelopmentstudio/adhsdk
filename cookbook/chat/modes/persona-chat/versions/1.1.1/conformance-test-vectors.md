
| ID | Requirements | Input | Expected |
|----|----|----|----|
| persona-chat-001 | route-by-mode | `mode='inline'`, backend, persona | Renders `InlineChat` component |
| persona-chat-002 | route-by-mode | `mode='three-pane'`, backend, persona | Renders `ThreePaneChat` component |
| persona-chat-003 | route-by-mode | `mode='mobile'`, backend, persona | Renders `MobileChat` component |
| persona-chat-004 | accept-backend | backend prop provided | Backend forwarded to child component |
| persona-chat-005 | accept-persona | persona prop provided | Persona forwarded to child component |
| persona-chat-006 | accept-user | user prop provided | User forwarded to child component |
| persona-chat-007 | accept-user | user prop omitted | Child component receives undefined user |
| persona-chat-008 | accept-welcome-message | welcomeMessage prop provided | Welcome message forwarded to child component |
| persona-chat-009 | accept-welcome-message | welcomeMessage prop omitted | Child component receives undefined welcomeMessage |
| persona-chat-010 | accept-class-name | `mode='inline'` or `'three-pane'`, className prop provided | className forwarded to child component |
| persona-chat-011 | accept-sizing-inline | `mode='inline'`, sizing prop provided | sizing forwarded to InlineChat component |
| persona-chat-012 | accept-sizing-inline | `mode='three-pane'`, sizing prop provided | sizing prop ignored; not forwarded to ThreePaneChat |
| persona-chat-013 | handle-mobile-open | `mode='mobile'`, open={true} | open={true} forwarded to MobileChat |
| persona-chat-014 | handle-mobile-open | `mode='mobile'`, open prop omitted | open={false} forwarded to MobileChat (default) |
| persona-chat-015 | handle-mobile-close | `mode='mobile'`, onClose callback provided | onClose forwarded to MobileChat component |
| persona-chat-016 | handle-mobile-close | `mode='mobile'`, onClose prop omitted | Default no-op callback forwarded to MobileChat |
| persona-chat-017 | accept-class-name | `mode='mobile'`, className prop provided | className not forwarded to MobileChat |
| persona-chat-018 | accept-sizing-inline | `mode='mobile'`, sizing prop provided | sizing prop ignored; not forwarded to MobileChat |
| persona-chat-019 | handle-mobile-close | `mode='inline'`, onClose callback provided | onClose not forwarded to InlineChat |
| persona-chat-020 | handle-mobile-open | `mode='inline'`, open prop provided | open not forwarded to InlineChat |
| persona-chat-021 | route-by-mode | `mode` set to a value outside `ChatMode` (untyped caller) | No switch case matches; component renders nothing (`undefined`) |

