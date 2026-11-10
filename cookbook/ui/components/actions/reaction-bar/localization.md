
The component builds its own accessible-name strings around the consumer-supplied `subjectLabel`:
`` `${emoji} ${count} on ${subjectLabel}` ``, `` `React to ${subjectLabel}` ``, and
`` `React ${emoji} to ${subjectLabel}` ``. Only `subjectLabel` comes from the consumer — the
surrounding English phrasing ("on", "React to", "React … to") is hardcoded in the component and
is not externalized or translated. The count is interpolated as a plain number without
locale-aware formatting (no `Intl.NumberFormat`), so a large count renders in a fixed,
non-localized digit grouping. See **string-externalization**, **no-hardcoded-strings**, and
**locale-aware-formatting** in Compliance.

