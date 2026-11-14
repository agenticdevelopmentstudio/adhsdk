
### Types

- **theme-key-union**: `ThemeKey` MUST be a closed union of exactly the 39 string literals listed in the Registered themes table.
- **theme-entry-shape**: `ThemeEntry` MUST carry `id` (a `ThemeKey`), `label` (a string) and `css` (a string).

### Registry

- **themes-record-total**: `themes` MUST be a `Record<ThemeKey, ThemeEntry>` with one entry for every `ThemeKey`; the compiler rejects a missing or extra key.
- **entry-id-matches-key**: Every entry's `id` MUST equal the key it is stored under. The type system does not enforce this, because `id` is typed `ThemeKey` rather than the record key; each entry is written out by hand.
- **entry-label-human**: Every entry's `label` MUST be the display name shown in the Registered themes table, including the non-ASCII forms `ADH · Comic` (middle dot) and `Rosé Pine`, and `Synthwave '84` with a straight apostrophe.
- **entry-css-nonempty**: Every entry's `css` MUST be the non-empty stylesheet string exported by `theme-data` under the name in the table's last column. The manifest does not check for emptiness itself; the test `rescued-themes.test.ts` asserts it for `crt-monitor` and `handheld-communicator`.
- **css-source-generated**: The manifest MUST NOT embed stylesheet text; it MUST import every stylesheet from `./theme-data`, the generated module.
- **unknown-key-lookup**: Looking up a key that is not in `themes` MUST yield `undefined`; the manifest provides no fallback, default theme or error. `ThemeStyle` handles that case by rendering nothing.

### Key list

- **theme-ids-derived**: `themeIds` MUST be `Object.keys(themes)` cast to `ThemeKey[]`, so it contains each of the 39 keys exactly once.
- **theme-ids-order**: `themeIds` MUST follow the declaration order of the `themes` literal (the order of the Registered themes table), not alphabetical order.
- **theme-ids-computed-once**: `themeIds` MUST be computed once at module load; adding a key at run time to `themes` does not update it.

### Module surface

- **manifest-exports**: The module MUST export `ThemeKey`, `ThemeEntry`, `themes` and `themeIds`. The package `index.ts` re-exports exactly these four from `./manifest`.
- **no-side-effects**: Importing the module MUST NOT touch the DOM, storage, network or files; its only effect is evaluating the imported stylesheet strings.
- **no-ordering-rules**: The manifest MUST NOT define a default theme, a grouping or a sort; consumers that need those own them.

### Registered themes

Declared in this order:

| Key | Label | Stylesheet export |
|-----|-------|-------------------|
| `adh` | ADH | `adhCss` |
| `adh-comic` | ADH · Comic | `adhComicCss` |
| `adh-courier` | ADH · Courier | `adhCourierCss` |
| `adh-dev-preview` | ADH · Dev Preview | `adhDevPreviewCss` |
| `adh-fira` | ADH · Fira | `adhFiraCss` |
| `adh-iosevka` | ADH · Iosevka | `adhIosevkaCss` |
| `adh-jetbrains` | ADH · JetBrains | `adhJetbrainsCss` |
| `adh-manrope` | ADH · Manrope | `adhManropeCss` |
| `agenticdevelopmentstudioweb` | Agentic Development Studio | `agenticdevelopmentstudiowebCss` |
| `charcoal` | Charcoal | `charcoalCss` |
| `dev-team` | Dev Team | `devTeamCss` |
| `fishlamp` | Fishlamp | `fishlampCss` |
| `green-matrix` | Green Matrix | `greenMatrixCss` |
| `green-matrix-glass` | Green Matrix (Glass) | `greenMatrixGlassCss` |
| `mikefullerton` | Mike Fullerton | `mikefullertonCss` |
| `myprojects` | My Projects | `myprojectsCss` |
| `myprojectsoverview` | Projects Overview | `myprojectsoverviewCss` |
| `old-school-terminal` | Old School Terminal | `oldSchoolTerminalCss` |
| `professional` | Professional | `professionalCss` |
| `techy` | Techy | `techyCss` |
| `terminal` | Terminal | `terminalCss` |
| `terminal-split` | Terminal Split | `terminalSplitCss` |
| `whimsical` | Whimsical | `whimsicalCss` |
| `gruvbox` | Gruvbox | `gruvboxCss` |
| `nord` | Nord | `nordCss` |
| `rose-pine` | Rosé Pine | `rosePineCss` |
| `signal` | Signal | `signalCss` |
| `solarized` | Solarized | `solarizedCss` |
| `catppuccin` | Catppuccin | `catppuccinCss` |
| `cobalt2` | Cobalt2 | `cobalt2Css` |
| `dracula` | Dracula | `draculaCss` |
| `github` | GitHub | `githubCss` |
| `monokai` | Monokai | `monokaiCss` |
| `one-dark` | One Dark | `oneDarkCss` |
| `synthwave84` | Synthwave '84 | `synthwave84Css` |
| `tokyo-night` | Tokyo Night | `tokyoNightCss` |
| `vesper` | Vesper | `vesperCss` |
| `crt-monitor` | CRT Monitor | `crtMonitorCss` |
| `handheld-communicator` | Handheld Communicator | `handheldCommunicatorCss` |

