
| State | Appearance change | Trigger behavior |
|-------|------------------|------------------|
| Not editable (`canEditTarget=false`) | `rename`, `move`, `file` and `delete` items visually disabled (grayed); `add` enabled | Only `add` is functional; the other items do not respond to click |
| Target selected (`canEditTarget=true`) | All five items visible and enabled | User can click any item |
| Disabled | Trigger appears disabled (visual state depends on GearMenuTrigger) | Trigger does not respond to click |
| Menu open | Dropdown content displays aligned per **align-to-end** | User can click any enabled item |

