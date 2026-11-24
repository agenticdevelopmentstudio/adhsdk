
- **SwiftUI**: Port as a free function over an array of a `Codable` `ErrorDTO` struct returning an
  `ErrorsSummary` struct. `filter`, `reduce` and `sorted(by:)` map one to one (read a missing or NaN count as 0 in the `events` sum); sort an enumerated
  array with the index as the tie-break, because Swift's `sorted` is not documented as stable, to
  keep `top-tie-order`.
- **Compose**: Port as a Kotlin top-level function over `List<ErrorDTO>` returning a data class.
  `filter`, `sumOf` (with a missing or NaN count read as 0) and `sortedByDescending` (stable) plus `take(5)` give the same result.
- **React/Web**: The source is a pure module in `status-server`. `Array.sort` is stable in current
  engines, which `top-tie-order` relies on. Clients render the figures and must not recompute them.
- **AppKit / UIKit**: No UI. Same port as SwiftUI; the figures feed whatever view the Errors card
  uses.
- **WinUI 3**: Port as a static method in a C# class library: count with
  `errors.Count(e => e.Active == true)` using `bool? Active` on an `ErrorDto` record, total with
  `errors.Sum(e => e.Count)`, treating a missing or NaN count as 0 as `events-total` does (for a
  nullable field, `e.Count ?? 0`, and for a `double`, map NaN to 0; use `long` if counts can be large), and build `top` with
  `errors.Where(e => e.Active == true).OrderByDescending(e => e.Count).Take(5)`. LINQ
  `OrderByDescending` is stable, matching the source. In an ASP.NET Core minimal API, call it from
  the `/telemetry` handler and serialize with `System.Text.Json` (camelCase naming policy) so the
  field names `active`, `backlog`, `events` and `top` match the contract. A WinUI client binds to
  the result through an `INotifyPropertyChanged` view model and must not recompute the figures.

