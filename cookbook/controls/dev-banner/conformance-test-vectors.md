
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dev-banner-001 | message-text | `message="Custom Alert"` | Rendered text equals `"Custom Alert"` |
| dev-banner-002 | message-text | No `message` prop provided (`undefined`) | Rendered text equals `'Development Preview — Coming Soon!'` |
| dev-banner-003 | position-class | `position="fixed"` | Container has class `awt-dev-banner--fixed` |
| dev-banner-004 | position-class | `position="static"` | Container has class `awt-dev-banner--static` |
| dev-banner-005 | default-position | No `position` prop provided | Container has class `awt-dev-banner--fixed` |
| dev-banner-006 | custom-class | `className="my-custom-class"` | Container class list includes `my-custom-class` |
| dev-banner-007 | custom-class | `className=""` (empty string) | Container class list contains only `awt-dev-banner` and the position class (no empty class token) |
| dev-banner-008 | hidden-from-at | Any props | Root element has attribute `aria-hidden="true"` |
| dev-banner-009 | base-class | `position="static"`, `className="extra"` | Container class list includes `awt-dev-banner` alongside `awt-dev-banner--static` and `extra` |
| dev-banner-010 | message-text | `message={null}` | Rendered text is empty; the default message is NOT used (the JS default parameter applies only to `undefined`) |
| dev-banner-011 | message-text | `message=""` | Rendered text is empty (container has no text content) |
| dev-banner-012 | message-text | `message="  padded  "` | Rendered text equals `"  padded  "` (leading/trailing whitespace preserved) |

