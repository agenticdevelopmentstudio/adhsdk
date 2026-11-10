
| State | Appearance change |
|-------|------------------|
| Default | Tab renders with no active indicator (transparent 2px bottom border). `aria-selected="false"`. `data-active` attribute is absent — React omits a `data-*` attribute whose value is `undefined`. |
| Active | Tab renders with active indicator (2px gold underline). `aria-selected="true"`. `data-active="true"` — React renders the boolean `true` passed to a `data-*` attribute as the string `"true"`. |
| Focused | Managed by browser focus styles and the `focus-visible:text-apt-text` utility (text-color change identical to hover; no separate focus ring, `outline-none`). |
| Disabled | Not supported: `AppTab` has no `disabled` property, and the component never sets a `disabled` attribute on any rendered button. Every tab remains interactive regardless of app state. |

