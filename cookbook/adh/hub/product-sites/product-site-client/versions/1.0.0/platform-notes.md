
- **SwiftUI**: Port the row as a `Codable` struct with optional `consoleLive` and `contentGated` defaulting to `false`, and the change as an `async throws` method sending a `PATCH` over `URLSession`; a typed error keeps the status, code and sentence.
- **Compose**: Use `kotlinx.serialization` data classes with default values for the two optional fields, and a repository whose update replaces the cached site on success.
- **React/Web**: This is the source platform: `packages/web/packages/data/src/product-sites/` with its tests in `__tests__/product-site-hook.test.tsx`. The file carries the `"use client"` directive and imports `@tanstack/react-query`; the package's `exports` map publishes the folder as `@adh-sdk/data/product-sites` and its build config lists the entry.
- **AppKit / UIKit**: The same Foundation approach as SwiftUI.
- **WinUI 3**: One shared `HttpClient` with a bearer handler, and `System.Text.Json` with `[JsonPropertyName]` on records.

