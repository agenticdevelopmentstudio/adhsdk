
**Decision**: The feature discriminator is a closed enumeration rather than a free-form string.
**Rationale**: The source types the `feature` argument as `AIFeature` and writes `feature.rawValue` to the log, so a misspelled feature cannot reach the log or the settings lookup. The cost is that a new feature needs a code change and a decision about its settings reader.
**Approved**: pending

**Decision**: Provider settings selection special-cases only `oversight`; every other case uses the general reader.
**Rationale**: The source gives oversight its own provider selection (its remapped reader) while summaries use the general one, and expresses that as one equality test. This keeps the common path unchanged and means a new case defaults to the general reader.
**Approved**: pending

