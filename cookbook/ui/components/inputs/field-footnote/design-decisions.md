
**Decision**: FieldFootnote does not use the standard `ErrorText` component; it renders its own error/hint spans at one shared size (`font-mono text-[0.7rem]`) instead of `ErrorText`'s `text-sm`.
**Rationale**: `ErrorText` uses `text-sm`, whose metrics differ from the hint text. If an error at `ErrorText`'s size swapped in for a hint at FieldFootnote's size, the differing text size/line height would shift the surrounding layout on the keystroke that made the value invalid. Giving error and hint identical metrics, differing only in color, keeps that swap layout-stable. `ErrorText` separately carries `role="alert"`; FieldFootnote does not, but that is an independent consequence of not reusing `ErrorText`, not a cause of the layout-stability decision — FieldFootnote's error is announced through `errorId`/`aria-describedby` instead (see **Accessibility**).
**Approved**: pending

**Decision**: FieldFootnote is exported as a standalone primitive rather than living only inside `Field`.
**Rationale**: Some form controls — notably checkboxes with custom row layouts — cannot use `Field`'s label structure and must build their own row, but still need to report validation feedback in the same place and words. Extracting FieldFootnote lets both `Field`-wrapped controls and custom-row controls share one implementation, so a fix to the error/hint logic does not have to be made twice and risk drifting between the two call sites.
**Approved**: pending

