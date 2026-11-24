
`columnDisplayValue(column, value)` in `@adh-sdk/crud` decides how one row value
reads in a list cell. The `/v1` API serves the `created` and `updated` row
timestamps as integer unix seconds, while every other timestamp column stays an
ISO string. This pure function converts only those two columns (when the column
descriptor says `integer` and the value is a number) into an ISO date string via
`unixToIso` from `@adh-sdk/auth/client`, and returns every other value exactly as
it was given.

It is a pure, synchronous function with no side effects. It is the single
conversion point both list surfaces share: `cellText` in `CrudTable` and the
cell rendering in `CrudDataView` each pass the raw row value through it before
their own null, stringify and truncate formatting. This recipe is
non-visual shared logic; see CrudTable ([adhsdk.ingredient.ui.crud.crud-table](cookbook:ec64b22b-8a25-431d-8866-b7a01acd91fe))
for the surface that shows its output.

