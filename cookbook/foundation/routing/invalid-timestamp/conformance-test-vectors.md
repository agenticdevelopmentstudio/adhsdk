
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| invalid-timestamp-001 | carries-message, init-takes-message | `InvalidTimestamp(message: "bad since").message` | `bad since`. |
| invalid-timestamp-002 | description-is-message | `InvalidTimestamp(message: "bad since").description` | `bad since`. |
| invalid-timestamp-003 | equatable-by-message | `InvalidTimestamp(message: "a") == InvalidTimestamp(message: "a")` | `true`. |
| invalid-timestamp-004 | equatable-by-message | `InvalidTimestamp(message: "a") == InvalidTimestamp(message: "b")` | `false`. |
| invalid-timestamp-005 | init-takes-message | `InvalidTimestamp(message: "").message` | The empty string: no validation is applied. |
| invalid-timestamp-006 | conforms-to-error | Use a value as the failure of `Result<String, InvalidTimestamp>`, then `throw` it. | Compiles and throws; the caught error is an `InvalidTimestamp` with the same `message`. |
| invalid-timestamp-007 | carries-message | `RouteRequest(method: "GET", path: "/events", queryValues: ["since": ["yesterday"]]).validatedTimestamp("since")` | `.failure` whose `message` contains both `since` and `yesterday` (test: aWordIsRejectedRatherThanSortingAboveEveryRealTimestamp in the RouteRequest tests). |
| invalid-timestamp-008 | carries-message | `RouteRequest.activitySince("yesterday")` | `.failure` whose `message` contains `` `since` `` (test: activitySinceTakesOnlyTheTextAndItsRefusalNamesSince in the RouteRequest tests). |

Vectors 001 to 006 are derived from the declaration; no test beside the source constructs the type directly. Vectors 007 and 008 are the existing assertions that exercise it through `RouteRequest`.

