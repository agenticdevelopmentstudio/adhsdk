
- **SwiftUI**: not applicable to these sources directly - none of the Swift files
  imports SwiftUI; they build form/level/detail value objects that a SwiftUI (or
  AppKit) rendering layer elsewhere consumes unchanged.
- **AppKit / UIKit**: this is one of the two source platforms. The files live under
  `packages/apple/AgenticDeveloperHubSDK/Hub/Features/EcosystemConfig/`
  (`AuthSettingsTopic.swift`, `EcosystemConfigModels.swift`,
  `FeatureFlagsTopic.swift`, `ServerBagsTopic.swift`, `SigninAppsTopic.swift`,
  `StorageTokensRail.swift`, `StorageTokensTopic.swift`), part of the
  `AgenticDeveloperHubSDKHub` sources directory that `project.yml` builds into both
  `AgenticDeveloperHubSDKHub-macOS` and `AgenticDeveloperHubSDKHub-iOS` targets from the same
  source tree - there is no platform-specific branch anywhere in these files. Each
  topic conforms to `EcosystemTopicProvider` and implements
  `child(for:path:rail:)`; every data-source call not covered by the exception
  below is wrapped in `HubError.wrap { ... }`, with specific mappings to
  `HubError.conflict`/`.validation`/`.unexpected` where the requirements above call
  for a distinct message.

  Three requirements exist only because of Swift's concurrency and protocol model
  and apply to this platform alone: `AuthSettingsTopic`, `SigninAppsTopic`,
  `FeatureFlagsTopic`, `ServerBagsTopic`, and `StorageTokensRail`/
  `StorageTokensTopic` are declared `@MainActor final class`, with every method
  that touches their own stored state running only on the main actor. Static
  helpers a `FormAction.perform` closure calls directly -
  `ServerBagsTopic.parsedValue`, `SigninAppsTopic.validateOrigin`/
  `canonicalOrigin`/`canonicalOrigins`, `StorageTokensRail.nameTakenMessage`/
  `createFailedMessage` - are declared `nonisolated`, because `FormAction.perform`
  closures are not `@MainActor`-isolated (per the source's own comments citing
  `FormSpec.swift`). `AuthSettings`, `AuthSettingsUpdate`, `SigninApp`,
  `SigninAppCreate`, `SigninAppUpdate`, `FeatureFlag`, `FeatureFlagCreate`,
  `FeatureFlagUpdate`, `ServerBag`, `ServerBagCreate`, `ServerBagUpdate`,
  `StorageToken`, `StorageTokenCreated`, and `StorageTokenCreate` are all declared
  `Codable, Hashable, Sendable` value types, so they can cross actor boundaries
  (e.g. into a `FormAction.perform` closure) without a data race.

  `AuthSettingsTopic.entry` declares `leadsTo: .detail`; the sign-up options come
  from `SignupMode.allCases`, parsed with `SignupMode(rawValue:)`, with help text
  from `SignupMode.help` (declared in `EcosystemConfigModels.swift`).
  `AuthSettings.allowedProviders: [String]?` decodes from
  `AuthSettingsDataSource.get`'s response but `AuthSettingsTopic.detail`'s form
  specification never surfaces it, and `AuthSettingsUpdate` has no field for it. The
  login allow-list (`login_allowed_emails`) is not decoded on Apple at all
  yet; that editor is planned.

  `SigninApp.leaf(in:)` implements leaf computation; the duplicate check compares
  against it case-insensitively; the `clientId` field validates against
  `Slug.pattern` with message `SigninAppsTopic.leafMessage`.

  The flags level's icon is `systemImage: "flag.fill"` when enabled or `"flag"`
  when disabled. `FeatureFlagsTopic.removalMessage` and
  `ServerBagsTopic.removalMessage` are the two distinct removal-message constants
  (**bags-removal-message-distinct-from-flags**). The wrapped JSON value type is
  `JSONValue` (`Support/JSONValue.swift`); its `.int`/`.number` cases are the two
  representations **bags-json-equality-int-number** reconciles;
  `ServerBagsTopic.parsedValue(_:)` discards `JSONValue.parse`'s specific
  `DecodingError`-derived message in favor of the fixed
  `ServerBagsTopic.invalidJSONMessage`; the detail save writes through
  `ServerBagUpdate.value`.

  `StorageTokensRail.child(path:ecosystemID:levelID:title:)` is the shared
  parameterized resolution operation; `StorageTokensRail.createSpec` implements the
  three-way catch and the reveal-once write via `MainActor.run`;
  `StorageTokensRail.aboutText(ecosystemID:)` returns `aboutWithoutEcosystem`/
  `aboutWithEcosystem`; the `name` field validates against `Slug.pattern` with
  `Slug.patternMessage`; `revealedSecrets`/`revealedOnScreen` are the rail's own
  `@MainActor`-isolated stored state, read and cleared by
  `expireRevealedSecret(unless:)`; the post-reveal notice text is
  `ApplicationsTopic.revealMessage`, declared in the sibling Applications module
  (see Design Decisions); date fields format through `HubDates.display`.

  The test suite (`EcosystemConfigTopicsTests.swift`) exercises every Apple topic
  against fakes with concrete assertions for each requirement above.
- **React / Web**: this is the other source platform. `feature-flags.ts`,
  `server-bags.ts`, `client-auth.ts`, `storage-tokens.ts`, and `wire.ts` under
  `packages/web/packages/data/src/ecosystem-config/` (plus shared helpers in
  `http.ts` and `client-helpers.ts`) are plain `fetch`-based clients with no JSX.
  `clientAuthApi` reads and `POST`s the ecosystem's and each application's
  client-auth settings, sending a `compact`ed body that drops undefined keys but
  keeps an explicit `registration: null`; `ecosystemFeatureFlagsApi.update`/`delete`
  embed `key` in the URL path via `enc()` (`encodeURIComponent`), as do the
  equivalent path segments in `server-bags.ts` and `client-auth.ts`. `tokenPrincipalsApi.list`/`mint`/`revoke`
  accept a `TokenScope` (`ecosystemId`/`workspace`, serialized by `scopeQuery`)
  independently of `MintTokenPrincipalBody.ecosystemId`, a separate body field;
  `TokenPrincipalCreated` (the 201-only body carrying `token`) is a distinct type
  from `TokenPrincipal` (the list-row shape, carrying only `prefix`).
  `EcosystemServerBag.value`/`EcosystemServerBagCreate.value`/
  `EcosystemServerBagUpdate.value` are typed `unknown` in `server-bags.ts`. The UI
  panes and dialog-state modules that call these clients live in
  `packages/web/packages/features/ecosystem-config/src/` (`FeatureFlagsPane.tsx`,
  `ServerBagsPane.tsx`, `StorageTokensPanel.tsx`, `ApplicationClientAuthSection.tsx`,
  `bag-dialog-state.ts`, `flag-dialog-state.ts`); see Design Decisions for the
  validation-layering split observed there.
  `signup-list.ts` in the data folder is the sign-up list client (`signupListApi`,
  with `list`, `put` and `remove`). The sets client lives in the sibling
  `@adh-sdk/data/sets` module, and the roles client and the ecosystem subject
  directory in `@adh-sdk/data/access` and `@adh-sdk/teams`; this ingredient only
  consumes them. The login allow-list is now two parts. `ClientAuthFields.tsx` draws
  the "Who can sign in" section, a switch with a pointer to the Sign-up list pane;
  `client-auth-model.ts` holds `cleanEmailList`, `policyPatch`, `samePolicy`,
  `allowListTurnedOn`, `allowListDropped`, `signupEmailError`, `registrationError`
  and the not-saved message; and `ClientAuthSettingsPane.tsx` seeds the form from the
  saved policy. The emails are typed in `SignupListPane.tsx`, because the hub has no
  owner-scoped customer listing to pick from. The email shape check is a local
  regular expression in `client-auth-model.ts`, because no shared web package
  exports an email validator; the backend's zod check stays authoritative.
  `pane-caller.ts` declares `PaneCaller` (`manager` or `product_admin`); the
  sign-up list, roles and sets panes take it as `caller`, and `SetsPane.tsx` exports
  `setEntryFeaturesFor` (the catalog entries a caller may edit),
  `USAGE_TIER_LIMIT_KEY` and `STORAGE_QUOTA_LIMIT_KEY`, importing the quota ceiling
  `DEFAULT_QUOTA_BYTES` from `@adh-sdk/data/product-admin`. `ProductRolesPane.tsx`
  exports `isAdminRole`. `ClientAuthFields.tsx` also exports `SettingRow`, the one
  labelled row with its control on the right, which the Product site pane draws its
  admin console switch with. The `ProductSitePane` (product sites phase 5, replacing
  the phase-6 `AdminSitePane`) and `ProductTotalsPane` are in the product admin site
  recipe.
  The phase-5 panes are `SignupListPane.tsx`, `ProductRolesPane.tsx` (with
  `RoleHolders`), `SetsPane.tsx` (with `refusalText` and `valuesOfDraft`) and
  `BillingPane.tsx`, each taking `{ ecosystemId, title, help }` so a host renders
  them through one signature; `EcosystemConfigGate.tsx` sits above them when the
  host holds a workspace rather than an ecosystem id. `SignupListPane`,
  `ProductRolesPane` and `SetsPane` read with `useResourceList` and guard writes
  with a single-flight flag; the sync-tables editor uses react-query hooks instead.
  The sync-tables topic is web-only. `sync-tables.ts` in the same data folder is
  the client (`syncTablesApi(family)`, `schemaOf`). `SyncTablesPane.tsx` in the
  features package holds `SyncTablesEditor` (the list and its progress modal, no
  chrome, `family` defaulting to `"ecosystem"`) and `SyncTablesPane` (the hub's
  `DetailsPane` around it); the hooks are in `sync-tables-hooks.ts`, keyed by
  family and ecosystem. Bulk actions run through `useBatchRun` from
  `@adh-sdk/data/query`. The admin console's `SyncPane` adds a picker over every
  ecosystem and mounts `SyncTablesEditor` with `family="admin"`, keyed on the
  ecosystem id; the hub's `[workspace]/sync` page mounts `SyncTablesPane`. Apple,
  Android and Windows have no sync-tables editor; it is planned.
- **Compose**: model each Apple protocol as a Kotlin `interface` with `suspend
  fun`s (e.g. `interface FeatureFlagsDataSource { suspend fun list(ecosystemId:
  String): List<FeatureFlag> }`); represent the shared token rail's revealed-secrets
  store as a `MutableStateFlow<Map<String, String>>` so Compose recomposition
  observes the reveal-once transition; model the wrapped JSON value type with
  `kotlinx.serialization.json.JsonElement`, noting the same integral-`Double`-vs-`Long`
  equality pitfall **bags-json-equality-int-number** documents applies to
  `JsonPrimitive` unless normalized the same way. Model the sync-tables client as a
  Kotlin `interface` with `suspend fun`s that return the refreshed catalog, the
  sign-up list as a `List<SignupListEntry>` of a lowercase email with an optional
  role id and set id, and the policy's allow-list as a switch, `null` meaning every
  customer and a non-null list meaning only the listed people.
- **WinUI 3**: model each data-source interface as a C# interface returning
  `Task<T>` (e.g. `Task<IReadOnlyList<FeatureFlag>> ListAsync(string
  ecosystemId)`) backed by `HttpClient` and `System.Text.Json` for
  (de)serialization, mirroring the `async`/`await` shape of Swift's `async throws`
  and TypeScript's `Promise`; back a level's item list with an
  `ObservableCollection<T>` (or a view-model implementing `INotifyPropertyChanged`)
  for a WinUI 3 `ListView`/`ItemsView`. For the shared token rail's reveal-once
  secret, keep the equivalent of `revealedSecrets` as a plain in-memory field on the
  view-model - deliberately never written to `Windows.Storage.ApplicationData` or
  any DPAPI-backed store - so the "shown once" contract this component enforces is
  preserved rather than accidentally persisted. Model the sync-tables client as a
  C# interface with one `Task`-returning method per operation, the sign-up list as
  a view-model over an `ObservableCollection<SignupListEntry>` (lowercase email,
  nullable role id and set id) with add and remove commands, and the sets editor as
  a view-model that builds one `CheckBox` per permission and one `NumberBox` or
  `TextBox` per limit from the catalog's entries, so no feature is named in the
  view.

