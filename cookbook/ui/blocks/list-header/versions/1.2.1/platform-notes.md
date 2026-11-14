
- **React/Web**: Implemented in `packages/web/packages/ui/src/blocks/list-header.tsx`,
  exported from `@adh-sdk/ui/blocks`. Built on `ButtonBar` (toolbar
  container, `role="toolbar"`) and the shared `Input` (native `<input type="search">`);
  uses Lucide's `Search` icon (`aria-hidden`). Behavior (see **autofocus-remount**):
  the filter field is focused whenever the header is newly attached to the DOM,
  never merely because it re-rendered. The implementation achieves this with a
  `ref` callback (`focusOnAttach`) passed only when `search.autoFocus` is true —
  React calls a `ref` callback on attach/detach, not on every render, so a stable
  callback identity (via `useCallback`) avoids stealing focus on a same-element
  re-render (e.g. a keystroke).
- **SwiftUI**: A SwiftUI port would compose an `HStack` with `Text` for the title
  (monospace, small, secondary color), a `TextField` styled as a search field with a
  leading `Image(systemName: "magnifyingglass")` — or, when the header sits at the
  top of a `NavigationStack`, the native `.searchable(text:)` modifier — a `Spacer()`
  for flex fill, and an `HStack` for actions, all wrapped in a toolbar-like container
  (e.g., `.background(Color.secondary.opacity(0.1))` with a bottom border). Autofocus
  (see **autofocus-remount**) maps to `@FocusState` set in `.onAppear` (or
  `.defaultFocus` on the field), which fires each time the view appears — including
  on remount — but not on a mere re-render of an already-appeared view.
- **Compose**: A Compose port would use a `Row` (`Modifier.fillMaxWidth()`) with
  `Text` (mono style, small size, muted color) for the title, a `TextField` with a
  leading icon for the search field — or Material 3's `SearchBar` where the platform
  idiom calls for it — a `Spacer(Modifier.weight(1f))` for flex fill, and a `Row` for
  actions. Autofocus (see **autofocus-remount**) maps to `LaunchedEffect(Unit)`
  calling `FocusRequester.requestFocus()`: the effect runs once each time the
  composable enters composition (mirroring attach/remount); recomposition of an
  already-composed instance does not re-enter composition, so it does not re-run
  the effect.
- **AppKit / UIKit**: A native port would use `NSSearchField` (AppKit) or a
  `UISearchBar` / the `.searchable` modifier (UIKit) for the search field, laid out
  with `NSStackView` (AppKit) or `UIStackView` (UIKit) using content-hugging and
  compression-resistance priorities — title highest hugging (never stretches),
  search lowest hugging (shrinks/grows first), actions in between — inside a
  toolbar-style container such as an `NSVisualEffectView` (AppKit) or a bar
  background (UIKit). Autofocus (see **autofocus-remount**) maps to
  `becomeFirstResponder()` called in `viewDidAppear()`, which fires on each
  appearance including remount, but is skipped on mere layout passes of an
  already-visible view.
- **WinUI 3**: A WinUI 3 port would use a `Grid` with column widths `Auto` (title),
  `*` (search — the `AutoSuggestBox` given an explicit `MaxWidth` to mirror the
  `max-w-xs` cap, see **filter-width-cap**, with `MaxWidth` cleared and
  `HorizontalAlignment="Stretch"` set when the port's grow equivalent is true),
  `*` (spacer), and `Auto` (actions). The native search control is `AutoSuggestBox`
  with `QueryIcon="SymbolIcon Symbol=Find"` and `PlaceholderText` for the placeholder.
  Autofocus (see **autofocus-remount**) maps to calling `Focus(FocusState.Programmatic)`
  in the `Loaded` event, which fires each time the control loads (mirroring
  attach/remount) but not on a mere property-change re-render of an already-loaded
  control. The container applies `Background="{ThemeResource ControlFillColorDefaultBrush}"`
  with a bottom `Border BorderBrush="{ThemeResource DividerStrokeColorDefaultBrush}"`.

