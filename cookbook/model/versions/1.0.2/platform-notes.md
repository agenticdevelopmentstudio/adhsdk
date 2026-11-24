
- **SwiftUI**: model `useSearchState`'s `query`/`selectedIndex` pair as
  `@Published` properties on an `ObservableObject` (or `@Observable` under
  Swift 6), recompute `results` in a `didSet`/computed property the way
  `useMemo` does, and drive `handleKey` from `.onKeyPress` (or
  `NSEvent.keyDown` on macOS) with the same `ArrowDown`/`ArrowUp`/`Escape`
  branching. `findBySlug`/`getBySection`/`getByDomain` map directly to
  `Array.first(where:)`/`.filter`; there is no first-party fuzzy-match
  equivalent to Fuse.js, so a port needs a Swift package (or a hand-rolled
  weighted scorer) that can reproduce the same threshold/weight semantics.
- **Compose**: hold `query` and `selectedIndex` in `mutableStateOf` (or a
  `StateFlow` in a `ViewModel`), and derive `results` with `derivedStateOf`
  keyed on `index`/`query`, mirroring `results-track-query`. Kotlin's
  `List.firstOrNull { }`/`.filter` cover the lookup functions directly. As on
  Apple platforms, Kotlin has no built-in fuzzy-match library matching
  Fuse.js's weighted, threshold-based scoring, so a port needs an equivalent
  third-party library or a custom scorer.
- **React/Web**: this is the source platform. The five files are
  `hooks/useSearchState.ts`, `lib/breadcrumbs.ts`, `lib/lookup.ts`,
  `lib/nav.ts`, and `lib/search.ts` in
  `packages/web/packages/model/src`, all consumed by `useSearchState.tsx`-style
  callers through `useMemo`/`useState`/`useCallback` and the `fuse.js`
  dependency declared in `packages/web/packages/model/package.json`.
- **AppKit / UIKit**: the lookup and breadcrumb functions translate directly
  to `NSArray`/`Array` predicate or block-based filtering; there is no
  React-style hook, so `useSearchState`'s state becomes a delegate/closure
  pair or a small controller object exposing the same `query`, `results`,
  `selectedIndex`, and key-handling methods, wired to `NSResponder`
  `keyDown(with:)` or `UIKeyCommand`. Note Foundation's
  `String.capitalized`/`localizedCapitalized` lowercase the remainder of each
  word and are locale-aware, unlike the source's `titleCase`, which only
  uppercases the first character and leaves the rest of each word's casing
  untouched — a literal port must replicate the source's naive behavior, not
  Foundation's, to stay conformant.
- **WinUI 3**: this is the platform this recipe exists to unblock. Expose
  `Query`, `Results`, and `SelectedIndex` as `INotifyPropertyChanged`
  properties on a view-model (or bind through `x:Bind` with
  `ObservableCollection<NavNode>` for the tree), replacing React's
  `useState`/`useMemo` with property setters that raise
  `PropertyChanged` and recompute `Results` inline. `findBySlug`,
  `getBySection`, and `getByDomain` map to LINQ's
  `.FirstOrDefault(predicate)` and `.Where(predicate).ToList()` over an
  `IEnumerable<SiteEntry>`. .NET's `System.Globalization.CultureInfo` /
  `TextInfo.ToTitleCase` is not a drop-in replacement for the source's
  `titleCase`: `ToTitleCase` lowercases the remainder of each word and
  applies locale rules, while the source only uppercases the first character
  of each `-`-split word and leaves the rest untouched — a conformant port
  must reimplement the source's exact character transform, not call
  `ToTitleCase`. There is no built-in fuzzy-match API in the .NET/Windows App
  SDK equivalent to Fuse.js's weighted, threshold-based scoring; a port needs
  either a NuGet package such as FuzzySharp (a different, Levenshtein-based
  algorithm, so scores and thresholds will not match numerically) or a
  hand-rolled scorer that reproduces Fuse.js's weighting (title `3`, summary
  `2`, domain `1`) and `0.3` threshold. Route `Escape`/`ArrowUp`/`ArrowDown`
  through `KeyDown`/`PreviewKeyDown` on the search `TextBox` or its hosting
  `AutoSuggestBox`, mapping to the same three branches as `handleKey`.

