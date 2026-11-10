
Not applicable: the three thrown error messages
(`"textlens: cannot read ... as a colour. ..."`,
`"textlens: fromColor and toColor go together — give both, or neither."`)
are fixed, non-localized diagnostic strings aimed at the developer who
misconfigured the lens, not user-facing text; the source performs no
locale-aware formatting or string lookup anywhere.

