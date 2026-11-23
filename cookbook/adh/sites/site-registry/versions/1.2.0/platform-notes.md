
- **SwiftUI**: No SwiftUI dependency exists in the source. A SwiftUI consumer would
  typically expose the registry's derived collections (the listed-sites set, the
  footer site list, the directory site list, category grouping's output) as plain
  `let` properties on an `@Observable` view model computed once at init, since none of
  the underlying data changes during a running process. The local-sites setting would
  come from `ProcessInfo.processInfo.environment`.
- **Compose**: A Kotlin port would model the site identifier type as a `sealed
  interface` or `enum class` rather than a string-literal union (closer to identifier
  validation's narrowing contract than TypeScript's own union erasure), a site
  definition and a brand story as `data class`es, and the derived `Set` and `Map`
  constants (the landing-segment set, the full workspace-segment set, the merged
  guided-tour graph, the fleet lists) as `kotlinx.collections.immutable` structures
  built once at object-initialization time, mirroring this module's compute-once-at-load
  pattern. The local-sites setting would come from `System.getenv`.
- **React/Web**: This is the source. The implementation lives under
  `packages/web/packages/adh-registry/src/sites/`: `registry.ts`, `reserved-slugs.ts`,
  `legal.ts`, `fleets.ts`, `story.ts`, the thirteen `routes.*.generated.ts` shares, and
  the hand-written `routes.generated.ts`, which declares `SITE_ROUTE_SHARES` and merges its values with
  `Object.assign` into `SITE_ROUTES`. `registry.ts` declares the `SiteId` union and
  the `SiteDef` shape (including the `nativeApp`, `featured`, `listed`, and
  `publicWorkspaceSegment` fields), the `SITES` array, environment and host resolution
  (`detectEnv`, `hostForEnv`, `localOrigin`, `servedLocally`, `buildSiteHref`,
  `siteUrl`), the hub's feature-segment map (`HUB_FEATURE_SEGMENT`,
  `SITE_FOR_HUB_SEGMENT`, `HUB_EXTRA_FEATURE_SEGMENTS`, `HUB_WORKSPACE_SEGMENTS`), the
  workspace-slug round trip (`siteWorkspaceHref` and `siteWorkspaceSlug` plus
  `SITE_LANDING_SEGMENTS` and `HUB_ROUTE_SEGMENTS`), the per-site build table
  (`SITE_BUILD` and `siteBuildConfig`) kept outside the file's `<gen:sites>` region, and
  `ssoReturnOrigins`. `reserved-slugs.ts` holds `RESERVED_SLUGS`, `isReservedSlug`, and
  `isReservedSlugAnywhere`. `legal.ts` holds the privacy and terms paths and URLs.
  `fleets.ts` holds `MARKETING_FLEET_SITE_IDS`, `PLACEHOLDER_FLEET_SITE_IDS`, and
  `DIRECTORY_SITES`. `story.ts` holds `SITE_STORIES`, `getSiteStory`, and the three
  generated rings `TOUR_MAIN`, `TOUR_MARKETING`, and `TOUR_PLACEHOLDER` merged by object
  spread into `SITE_TOUR_NEXT`. A site's build-tree directory name is a Next.js
  app-router folder derived by `dirNameOf`; a site's workspace route is a Next.js
  `app/[workspace]` dynamic route. `servedLocally` reads
  `process.env.NEXT_PUBLIC_LOCAL_SITES` spelled out in full, because Next inlines a
  `process.env.NEXT_PUBLIC_*` reference only where the literal text appears.
  `personaProfileUrl` reads the current hostname from
  `globalThis.location?.hostname ?? ''` rather than `window`, because this file is also
  type-checked in a backend build with no DOM library. The files are pure TypeScript
  with no React import, consumed by React components (the header, switcher, and footer)
  elsewhere in the same web packages; a caller re-implementing this in another JS or TS
  codebase should keep the same pure-data, pure-function shape rather than folding any of
  it into a component or a hook, since several exports (`ssoReturnOrigins`, the route
  shares) are consumed by non-React code that would break if the logic moved into a
  component. Nothing in the module uses `async` or `Promise`, and the only runtime input
  is the environment variable.
- **AppKit / UIKit**: These are TypeScript and web sources with no Apple-framework
  dependency. A macOS or iOS port would model a site definition and a brand story as
  `Codable` `struct`s, the site roster and the brand-story map as `static let` constants
  (loaded from a bundled JSON or a generated Swift file rather than re-typed by hand),
  and environment detection, cross-site link construction, and the return-origin list as
  pure functions over `URLComponents` and `String`, with no `NSObject` subclassing
  needed anywhere. Kitchen and Stenographer, the two `nativeApp` sites, are themselves
  macOS tools, so a port inside them would use the legal URLs as plain `URL` constants
  opened with `NSWorkspace` or `UIApplication`.
- **WinUI 3**: A .NET port would model the site identifier type as an `enum`, a site
  definition and a brand story as `record`s (immutable by default, matching this
  module's `readonly` shape), and the derived set and map constants as `FrozenSet<string>`
  and `FrozenDictionary<TKey, TValue>` built once in a static constructor. Environment
  detection, host resolution, and local-origin resolution become pure `static` methods
  over `Uri` and `string`, and the local-sites setting is read with
  `Environment.GetEnvironmentVariable` on each call. `System.Text.Json` would
  deserialize the roster if it shipped as a generated JSON asset, and that asset, if
  packaged with the app, would be read once at startup with `Windows.Storage` (for
  example `StorageFile.GetFileFromApplicationUriAsync`) inside a `Task`-returning
  `async` initializer, which is the one place this port differs from the source, where
  every export is synchronous. `HttpClient` is not needed, since nothing here performs a
  network call, and `ObservableCollection` and `INotifyPropertyChanged` are not needed,
  since no value changes after process start; a view model that binds the footer
  directory can expose a plain `IReadOnlyList<SiteDef>`.

