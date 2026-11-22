
- **SwiftUI**: Model the row shapes as `Codable, Hashable, Sendable` structs with
  `CodingKeys` mapping snake_case to camelCase, and the target as an enum with `workspace` and
  `ecosystem` cases. Expose `accessApi` as an `actor` or `@MainActor` class of `async throws`
  methods on `URLSession`, build query items with `URLComponents` so values are percent-encoded,
  and throw an error type carrying the HTTP status and optional code. Swift has no
  `JSON.stringify` omission of undefined, so omit optional fields with `encodeIfPresent`.
- **Compose**: Model the rows as `@Serializable` data classes with `@SerialName` for the
  snake_case members, the target as a sealed interface, and `accessApi` as a class of
  `suspend fun` methods on Ktor or OkHttp. Use `HttpUrl.Builder` or Ktor `parameters` for the
  query, and set `explicitNulls = false` so unset optional fields are omitted from bodies.
- **React/Web**: Source platform. `packages/web/packages/data/src/access/access.ts` holds
  `accessApi`, `accessTargetQuery`, `accessTargetKey`, `ACCESS_FEATURES` and the two input
  types; `wire.ts` holds the camelCase rows, the `*Wire` shapes and `AccessTarget`; `index.ts`
  re-exports both. The calls are built on `authedJson`, `authedRequest`, `listAllV1` and
  `withV1Query` (re-exported through `http.ts` from `@adh-sdk/auth/client`) and `enc`
  (`encodeURIComponent`) from `client-helpers.ts`. Optional body fields are omitted with
  conditional spreads, so an unset field never reaches the body. The refresh-on-401
  waterfall and `AuthHttpError` live in `auth/src/client.ts`.
- **AppKit / UIKit**: No UI dependency exists. A macOS or iOS feature consumes the ported
  client through an injected data-source protocol, so views never call `URLSession`, and keys
  its caches with the string `accessTargetKey` produces. Present the role matrix with
  `NSTableView` or `UITableView` and fall back to the fixed list on a failed features load.
- **WinUI 3**: Model rows as C# `record`s read with `System.Text.Json` and
  `JsonPropertyName("is_system")`-style attributes, set `JsonIgnoreCondition.WhenWritingNull` to
  mirror the omitted optional fields, and model the target as a discriminated record pair.
  Implement `AccessApi` as a class of `Task<T>` methods on one shared `HttpClient`, with a
  `DelegatingHandler` attaching `Authorization: Bearer <token>` and doing the one refresh and
  one retry on a `401`. Build query strings with `Uri.EscapeDataString` or
  `HttpUtility.ParseQueryString`, throw an `AccessApiException` (`HttpStatusCode`, `Code`)
  parallel to `AuthHttpError`, page roles with a loop on `has_more` and `starting_after`, and
  read a 204 as `HttpStatusCode.NoContent` to keep the restrict and restore behavior. Bind
  the matrix to an `ObservableCollection<AccessRoleRow>` in an `ItemsRepeater` or `ListView`,
  with `INotifyPropertyChanged` on the view model, not on this client.

