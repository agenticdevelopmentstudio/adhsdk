
| Option | Behavior |
|--------|----------|
| Reduce Motion | Carried as the `reduceMotion` pref (`auto`, `on`, `off`) and painted as `data-reduce-motion`; `auto` removes the attribute so the `prefers-reduced-motion` media query governs. The store does not listen for that query. |
| Increase Contrast | Carried as the `contrast` pref (`default`, `high`, `extra-high`) and painted as `data-contrast`; `default` leaves the attribute off so `prefers-contrast` governs. The store does not listen for that query. |
| Differentiate Without Color | The store has no colour-only signal. It carries the `focusOutlines` and `underlineLinks` prefs, painted as `data-*="always"`. |

