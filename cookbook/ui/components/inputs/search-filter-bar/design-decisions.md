
- **Decision**: Both the search field and every filter select are fully
  controlled, with caller-supplied option sets.
  **Rationale**: explicit-over-
  implicit — the bar owns no list/data state; it cannot desync from the consumer,
  and the consumer keeps option universes stable so narrowing never empties a
  dropdown.
  **Approved**: pending
- **Decision**: An option is a bare string *or* a `{ value, label }` pair, and the
  two mix on one axis.
  **Rationale**: the original `string[]` was a yagni bet that
  a consumer proved wrong — an axis over *records* (a status, an iteration, an
  owner) filters by id and reads as a name. Making the caller keep a label↔id
  codec of its own would be a lossy guess about data it already holds correctly:
  two ids can share a display name, and two names can share an id. The bare string
  stays as the shorthand for the case where they coincide, so no existing caller
  had to change.
  **Approved**: pending
- **Decision**: `children` land in the filter row rather than in a config union.
  **Rationale**: yagni / optimize-for-change — `filters` covers the single-select
  axis, which is most of them; an axis that is genuinely a different control (a
  multi-select, a date range, a toggle group) composes at the call site instead of
  growing a union that has to describe every control the platform will ever filter
  with. The bar supplies the landmark, the field and the row.
  **Approved**: pending
- **Decision**: `asForm` lives here, off by default, rather than each host
  wrapping the bar in its own `<form>`.
  **Rationale**: dry — "a search field with
  no form ancestor is autofilled against the whole document" is a property of
  search fields, not of any one page, and it is a measured platform quirk that
  needs a paragraph to be legible at a call site. Default-off because a bar
  rendered inside a host's own form would nest one, which the parser resolves by
  dropping it.
  **Approved**: pending
- **Decision**: Compose the existing `Input` + `Select` primitives rather than
  restyle.
  **Rationale**: dry / consistency — the bar inherits the standard
  focus-ring and token treatment, so it matches every other field on the platform.
  **Approved**: pending
- **Decision**: The filter row is omitted entirely when `filters` is empty.
  **Rationale**: principle-of-least-astonishment — a search-only bar shows no empty
  control row.
  **Approved**: pending

