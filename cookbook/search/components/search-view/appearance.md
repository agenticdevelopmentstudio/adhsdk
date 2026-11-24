
- **Corner radius**: Preview dock: 0.75rem. Error blocks and empty-state cards (zero-results, inactive prompt): 0.5rem.
- **Padding**: Root stack: 1rem (16px) gap between the search bar, the filter chips, and the list/preview area. Filter chips: 0.5rem (8px) gap between chips. Preview dock header: 0.75rem horizontal × 0.5rem vertical. Result list: 0.75rem (12px) gap between items. Result list container: small right padding (0.25rem / 4px) reserved for the internal scrollbar.
- **Font**: Result count label: 0.75rem. Chip labels: inherited from Badge. Preview title (collapsed): 0.875rem, medium weight. Preview subtitle: 0.75rem. Error message: 0.875rem. Empty/zero-results title: 0.875rem, medium weight; its hint text: 0.75rem.
- **Background**: Preview dock: `apt-surface` (primary surface token). Error blocks: `apt-red` at 5% opacity. Loading skeleton: `apt-surface-2` (secondary surface token). Chip hover: `apt-surface-2`.
- **Foreground/Text**: Result count: `apt-text-dim` (muted text token). Chip text: inherited from Badge; chip hover text: `apt-text`. Preview subtitle: `apt-text-muted`. Error text: `apt-red`. Empty/zero-results title: `apt-text-muted`; its hint text: `apt-text-dim`.
- **Border**: Default border color: `apt-border`. Error blocks: `apt-red` at 40% opacity. Preview dock: 1px border, `apt-border`, drawn with the 0.75rem corner radius above. Between the dock's header and its content region (when disclosed): 1px top border, `apt-border`. Empty/zero-results cards: dashed border, `apt-border`.
- **Shadow**: None.
- **Min/Max size**: The split container (list + divider + preview dock) targets 65% of viewport height with a 320px floor on small viewports, and 70% of viewport height with a 420px floor from the small breakpoint up. Both the result list and the disclosed preview dock are allowed to shrink below their content size so they scroll internally rather than overflow the container. Individual result rows are otherwise unconstrained in height.

