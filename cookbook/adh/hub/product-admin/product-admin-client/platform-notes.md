
- **SwiftUI**: Port the wire types as `Codable` structs with `CodingKeys` and the roster page as an `async throws` method over `URLSession`, keeping `ecosystem` as a query item. A cache that invalidates the roster and totals together replaces the React Query hooks.
- **Compose**: Use `kotlinx.serialization` data classes with `@SerialName`, and a repository whose write functions refresh the roster and totals flows together.
- **React/Web**: This is the source platform: `packages/web/packages/data/src/product-admin/` with its tests in `__tests__/product-admin.test.ts`. The files carry the `"use client"` directive and import `@tanstack/react-query`; the package's `exports` map publishes the folder as `@adh-sdk/data/product-admin` and its build config lists the entry.
- **AppKit / UIKit**: The same Foundation approach as SwiftUI; `JSONDecoder` with `convertFromSnakeCase` fits every row here.
- **WinUI 3**: One shared `HttpClient` with a bearer handler, and `System.Text.Json` with `[JsonPropertyName]` on records.

