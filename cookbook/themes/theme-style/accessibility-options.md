
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the module animates nothing; any media-query handling lives in the theme stylesheets it passes through. |
| Increase Contrast | Not applicable to the code itself: it moves `[data-contrast=...]` qualifiers onto an `html` ancestor so contrast variants in a theme keep working inside a scope, but it reads no preference. |
| Differentiate Without Color | Not applicable: the module has no visual output of its own. |

