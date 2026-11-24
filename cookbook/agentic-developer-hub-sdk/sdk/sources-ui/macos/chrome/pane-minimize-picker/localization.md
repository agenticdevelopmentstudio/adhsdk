
`PaneEdge.displayName` hardcodes its four label strings in English ("Minimize to Top", "Minimize to Left", "Minimize to Bottom", "Minimize to Right") directly in the enum; these strings are used verbatim as the accessibility label, the tooltip, and the SF Symbol's accessibility description. The component, not the calling code, owns these strings, and they are not currently externalized to a localization resource — see **string-externalization** in Compliance.

