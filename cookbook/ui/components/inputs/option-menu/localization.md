
Most user-facing strings are passed via props (`ariaLabel`, `otherLabel`, `placeholder`, `otherPlaceholder`), letting callers localize at point of use. The **OK** button's label is the exception: it is hard-coded as `"OK"` with no prop to override it, so a caller cannot localize that one string (see **no-hardcoded-strings** in Compliance).

