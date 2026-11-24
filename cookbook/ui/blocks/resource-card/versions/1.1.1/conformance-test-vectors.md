
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| resource-card-001 | render-title | `title="My App"` | Title "My App" is rendered as plain text in font-medium. |
| resource-card-002 | accept-href | `href="/app"` | Root element is an anchor or LinkComponent with href="/app". |
| resource-card-003 | accept-onclick, button-focusable | `onClick={handler}` without href | Root element is a div with role="button" and tabIndex=0. |
| resource-card-004 | href-precedence | `href="/app"` and `onClick={handler}` | onClick handler is executed, then navigation to /app proceeds; navigation is not delayed by the handler. |
| resource-card-005 | use-link-component | `href="/app"` and custom LinkComponent | LinkComponent is rendered with to="/app" prop. |
| resource-card-006 | fallback-link-component | `href="/app"` without LinkComponent | Native `<a href="/app">` is rendered. |
| resource-card-007 | keyboard-activation | role="button" and Space key pressed | onClick handler is invoked and the keydown event's default action is prevented (no page scroll). |
| resource-card-008 | keyboard-activation | role="button" and Enter key pressed | onClick handler is invoked. |
| resource-card-009 | optional-identifier | `identifier="com.example.app"` | Identifier is rendered in monospace, text-xs, below title. |
| resource-card-010 | optional-identifier | No identifier prop, or `identifier=""` | No identifier text is rendered. |
| resource-card-011 | optional-description | `description="A great app"` | Description is rendered in text-sm, muted color, clamped to 3 lines. |
| resource-card-012 | optional-description | No description prop, or `description=""` | No description text is rendered. |
| resource-card-013 | optional-meta | `meta={<span>iOS</span>}` | Meta content is rendered in flex-wrapped row, monospace, text-xs. |
| resource-card-014 | optional-meta | No meta prop | No meta row is rendered. |
| resource-card-015 | interactive-styling | href or onClick provided | Cursor is pointer; hover and focus-visible states are applied. |
| resource-card-016 | interactive-styling | Neither href nor onClick provided | Cursor is default (not pointer); hover and focus states are not visible. |
| resource-card-017 | classname-support | `className="custom-class"` | Custom class is applied to the outermost element along with defaults. |
| resource-card-018 | left-aligned-text | Any props | Text content uses text-left alignment. |
| resource-card-019 | meta-no-nested-interactive | `href="/app"` and `meta={<a href="/x">link</a>}` | No `<a>`, `<button>`, or `[role="button"]` descendant exists inside `meta` when the card itself is an anchor or role="button" element. |

