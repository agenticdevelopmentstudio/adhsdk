
Document which accessibility display options (Rule 15) this component responds to:

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable — the component has no animations or motion effects to reduce. |
| Increase Contrast | Not implemented. The disabled submit button relies on a fixed 50% opacity reduction (`disabled:opacity-50`) regardless of the system's increase-contrast setting; there is no dedicated high-contrast styling path. |
| Differentiate Without Color | Largely satisfied incidentally: the error state is conveyed through message text (not color alone) plus `role="alert"` and `aria-invalid`, so a visitor who cannot perceive the red (`text-red-600`) still reads the same words. There is no separate color-only indicator, such as a border-color-only invalid state, that would fail if color were removed. |

