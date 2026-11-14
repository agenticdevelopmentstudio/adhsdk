
| State | Appearance change |
|---|---|
| Idle / collapsed | input only; `aria-expanded="false"` |
| Focused | `focus-visible` ring `apt-gold/25` |
| Typing, matches | popup open with filtered suggestions |
| Typing, no match | popup open with the empty message |
| Active suggestion | `bg-apt-highlight/15` on the active row; `aria-activedescendant` set |
| Disabled | dimmed; non-interactive; popup cannot open |

The control filters the in-memory `items` prop synchronously, so it owns no
intrinsic loading or error state; a caller fetching suggestions passes the resolved
array (an async caller can show its own spinner alongside).

