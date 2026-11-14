
- **native-list**: `BuiltInThemes.webPortedNative` MUST contain one entry for every theme in `BuiltInThemes.webPorted`, in the same order.
- **native-map**: `webPortedNative` MUST be the result of passing each `webPorted` theme through `nativeAdjusted`, and MUST NOT add, remove or reorder themes.
- **dispatch-by-id**: `nativeAdjusted` MUST select the adjustment by `theme.id`, never by name or position.
- **dispatch-fishlamp**: `nativeAdjusted` MUST apply the Fishlamp adjustment when `theme.id` equals the id of the generated `BuiltInThemes.fishlamp` theme.
- **dispatch-default**: `nativeAdjusted` MUST return any theme whose id has no adjustment unchanged.
- **input-preserved**: `nativeAdjusted` MUST NOT mutate its argument; the Fishlamp adjustment MUST work on a copy and return it.
- **fishlamp-selection**: The Fishlamp adjustment MUST set `selection` to `#232831ff`, replacing the generated amber `#e8a33d4d`.
- **fishlamp-card**: The Fishlamp adjustment MUST set `roleOverrides[ThemeRole.card.rawValue]` to `#17130fff`.
- **fishlamp-selection-edge**: The Fishlamp adjustment MUST set `roleOverrides[ThemeRole.selectionEdge.rawValue]` to `#e8a33dff`, so a selection is marked by an amber line.
- **fishlamp-pane-backdrop**: The Fishlamp adjustment MUST set `project` to a `ThemeProjectOptions` whose only non-nil field is `paneBackdrop`, equal to `#17130fff`.
- **fishlamp-project-replaced**: The Fishlamp adjustment MUST replace the theme's whole `project` value, discarding any `highlightActivePane` or `paneOutline` already present.
- **fishlamp-overrides-merged**: The Fishlamp adjustment MUST add or replace only the `card` and `selectionEdge` keys of `roleOverrides` and MUST leave every other key (for example the chat roles the generator emitted) as generated.
- **fishlamp-untouched-fields**: The Fishlamp adjustment MUST NOT change `id`, `name`, `appearance`, `foreground`, `background`, `cursor`, `ansi` or `typography`.
- **ember-shared**: The Fishlamp adjustment MUST make the card colour and the pane backdrop equal, both `#17130fff` (the theme's own ANSI slot 8).
- **hex-literals**: Every colour literal in the adjustment MUST be a valid 8-digit `RRGGBBAA` string, because the Swift implementation parses it with `RGBAColor(hexString:)` and force-unwraps the result.
- **access**: `webPortedNative` and `nativeAdjusted` MUST NOT be `public` (they are internal to the SDK module), and `fishlampNative` MUST be `private`; consumers MUST read the result only through `BuiltInThemes.all` and `BuiltInThemes.theme(withID:)`.
- **concurrency**: `webPortedNative` and `nativeAdjusted` MUST be pure and synchronous, and MUST be safe to call from any thread. In Swift `webPortedNative` is a `static let`, initialised once, lazily and thread-safely, by the language runtime on first access; the file declares no actor, lock or queue.
- **side-effects**: The adjustment MUST NOT perform file, network, process or notification side effects and MUST NOT write logs.

