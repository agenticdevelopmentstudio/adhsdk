
**Decision**: document Behavioral Requirements as ~60 discrete, grouped
requirements rather than compressing the full validation surface into a
handful of broad statements.
**Rationale**: the source validates on the order of sixty distinct
invariants across six file types (palette/ink resolution, rig/channel
derivation, pose/timeline/behavior cross-references, variant patches,
sayings fallback); a comparable-complexity recipe should track that
complexity rather than a template's usual UI-widget scale, per the
cross-recipe-consistency guideline's "comparable complexity is defined by
distinct behaviors, not visual simplicity."
**Approved**: pending

**Decision**: state the reference-integrity, pair-fields-exactly-two, and
value-type-matches-channel rules once each as a shared mechanism, listing
every call site, rather than repeating a near-identical bullet per field.
**Rationale**: each of these is genuinely one rule applied uniformly at many
authoring sites in the source; restating it per site would be a compound
requirement's opposite failure — needless duplication that obscures that
it is one mechanism, not many.
**Approved**: pending

**Decision**: include the Apple-only `raw-file-read-errors-unwrapped`
requirement as a documented asymmetry rather than a defect to flag.
**Rationale**: the behavior is real, source-observable, and consistently
reproducible (an un-wrapped Foundation/`JSONDecoder` error from
`RawFiles.read(fromDirectory:)`); it does not meet the bar for an
unimplemented-behavior marker because the source fully answers what
happens, it simply answers it inconsistently with
`CharacterConfig.load(_:)`'s own wrapping.
**Approved**: pending

