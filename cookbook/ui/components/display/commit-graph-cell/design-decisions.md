
**Decision**: Lane colours are ANSI slots 1–6 and 9–14 of the theme rather than a palette of their own.
**Rationale**: The ANSI 16 is the vocabulary terminal-derived themes are authored in, so every theme already has twelve distinct, background-contrasting hues; a separate graph palette would be a second colour source to keep in step.
**Approved**: pending

**Decision**: A merge is recognised from the row itself (two or more bottom segments leaving the commit's column) rather than from a flag the layout adds.
**Rationale**: Every bottom segment from the commit's column is one parent edge, pass-through segments never start there, so the row already says it; the layout's `Row` stays unchanged.
**Approved**: pending

