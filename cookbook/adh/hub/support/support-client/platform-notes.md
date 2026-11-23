
- **SwiftUI**: Port the wire types as `Codable` structs with `CodingKeys` and each client as an `async throws` service over `URLSession`; keep the viewer read-only by exposing no write method.
- **Compose**: Use `kotlinx.serialization` data classes with `@SerialName`, and a repository whose writes refresh the grants and log flows together.
- **React/Web**: The source platform: `packages/web/packages/data/src/support/`. `wire.ts` and `grants.ts` carry the `"use client"` directive, and `grants.ts` imports `@tanstack/react-query`; the package's `exports` map publishes the folder as `@adh-sdk/data/support`, with `types` at `./dist/support/index.d.ts`, `development` at `./src/support/index.ts` and `import` at `./dist/support/index.js`.
- **AppKit / UIKit**: The same Foundation approach as SwiftUI.
- **WinUI 3**: One shared `HttpClient` with a bearer handler, and `System.Text.Json` with `[JsonPropertyName]` on records.

