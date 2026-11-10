
**Decision**: Apply an explicit two-column grid track (`lp-cards--pair`) when the caller flags a four-item set as `pair`.
**Rationale**: CSS Grid's shared `auto-fit` track lays four cards out as 3 + 1 at typical card widths, creating a visually incomplete trailing row; forcing two columns keeps four items balanced as 2×2.
**Approved**: pending

**Decision**: Apply an explicit three-column grid track (`lp-cards--trio`) when the caller flags a nine-item set as `trio`.
**Rationale**: The same shared `auto-fit` track lays nine cards out as 4 + 4 + 1; forcing three columns keeps nine items visually balanced instead of leaving a lone trailing item.
**Approved**: pending

**Decision**: Throw synchronously when both `pair` and `trio` are `true`, rather than resolving the conflict silently.
**Rationale**: Both props set the same CSS grid track; permitting both to be `true` would produce a result that depends on stylesheet cascade order, an ambiguity the component prevents by treating it as a caller error.
**Approved**: pending

**Decision**: Native ports SHOULD model `pair`/`trio` as a single `columns?: 'pair' | 'trio'` enum (or the platform equivalent), rather than as two independent booleans.
**Rationale**: The web source exposes `pair` and `trio` as independent optional booleans and only rejects the conflicting-props state by throwing at render time (see **reject-conflicting-props**); an enum-shaped prop makes that invalid state unrepresentable instead of merely caught at runtime.
**Approved**: pending

