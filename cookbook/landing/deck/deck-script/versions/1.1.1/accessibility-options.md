
DeckScript operates at the initialization layer and performs no Reduce Motion check itself. The CSS contract (see **css-contract**) is what MUST honor `prefers-reduced-motion`; a caller who wants to skip arming entirely, rather than rely on that CSS override, MAY also pass `armSmooth: false`.

