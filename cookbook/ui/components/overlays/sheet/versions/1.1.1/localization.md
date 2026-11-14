
Sheet does carry one user-visible string: the close button's screen-reader label, "Close" (see **close-button-accessible-label**). It is hardcoded in `sheet.tsx` rather than sourced from a localization resource, so it renders in English regardless of the consuming app's locale — a real i18n gap in the current source, not a "not applicable" case.

