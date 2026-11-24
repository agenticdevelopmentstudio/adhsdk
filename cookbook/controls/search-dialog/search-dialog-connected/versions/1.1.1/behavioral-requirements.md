
- **forwarded-props**: Component MUST accept and forward all SearchDialogProps except `state`, `onSelect`, and `sectionLabels` as specified by SearchDialogConnectedProps. `onClose` specifically is required (typed as `() => void`, not optional) because the selection handler below calls it directly.
- **search-state**: Component MUST compute search state by calling `useSearchState(searchIndex)` where searchIndex is obtained from `useContent()`.
- **section-labels**: Component MUST compute a mapping from section key to section label by iterating `nav.sections` from `useSiteConfig()`.
- **select-navigates**: Component MUST handle selection by calling `navigate(entry.slug)` (from `useCurrentRoute()`) and then calling the forwarded `onClose` callback.
- **renders-dialog**: Component MUST render the SearchDialog component with all computed values and forwarded props, passing computed state, mapped sectionLabels, and the selection handler.

