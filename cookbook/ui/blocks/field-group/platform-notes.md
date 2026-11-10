
- **SwiftUI**: Use `Form` with a `Section(header:)` as the native grouping container — `Section`'s header holds the uppercase-mono title `Text`, with an optional trailing view alongside it in an `HStack` (`.frame(maxWidth: .infinity, alignment: .trailing)` on the trailing side), and the section's content closure holds the grouped field rows in place of `children`. Outside a `Form` context, use a `GroupBox` with the same header/content split.
- **Compose**: Use an `OutlinedCard` as the bordered container, with a `Row` header inside — an uppercase-mono `Text` title and an optional trailing composable, laid out via `Arrangement.SpaceBetween` — followed by a `Column` holding the grouped field rows in place of `children`.
- **React/Web**: Implemented in `packages/web/packages/ui/src/blocks/field-group.tsx`, exported via `@adh-sdk/ui/blocks/field-group`. The component carries `"use client"` at the top of the file; nothing in its own render path (no hooks, no state, no event handlers) needs it, and the `Field` ingredient it composes ships without the directive at all. It composes `Field` ([adhsdk.ingredient.ui.blocks.field](cookbook:0c199036-81c3-47c3-9e79-e4b8187ca69a)) as its children plus the shared `fieldCaptionClass` for the title. Used platform-wide as the sectioning wrapper in settings/editor panes; commonly the last group in such a pane is a destructive "danger zone" section. Verify responsive behavior via Playwright (ui-showcase) at 375 / 768 / 1440 — the title/trailing row and the stacked Fields stay usable on mobile.
- **AppKit / UIKit**: AppKit — use an `NSBox` (`.boxType = .custom`, `.borderType = .lineBorder`) as the bordered container, with its title view holding an uppercase-mono `NSTextField` and an optional trailing `NSView` laid out in a horizontal stack. UIKit — use a grouped `UITableView`/`UICollectionView` section: the section's header view carries the uppercase-mono title label and an optional trailing accessory view, and the section's rows hold the grouped fields.
- **WinUI 3**: Use a vertical `StackPanel` with `Spacing="12"` as the root container (the web `gap-3` is 12px). Apply `Padding="12"`, `BorderBrush` bound to the border token with `BorderThickness="1"` as a literal, `CornerRadius="8"`, and `Background` bound to the surface token for the recessed card effect. Make the title row a `Grid` with `ColumnDefinitions="*,Auto"` and `ColumnSpacing="8"` (the web `gap-2`) — a `TextBlock` header (uppercase letter-spacing to match the web `fieldCaptionClass`) in column 0, and an optional trailing `UIElement` in column 1 — since a `Grid`'s columns give the trailing element real right-alignment where a horizontal `StackPanel` ignores `HorizontalAlignment` on its children. Below the title row, add a vertical `StackPanel` with its own `Spacing="12"` for the grouped field rows — `StackPanel` does not propagate `Spacing` to a nested panel, so each stack sets it explicitly. No interactive states required — the component is a stateless layout wrapper.

API (`@adh-sdk/ui/blocks/field-group`):

```ts
interface FieldGroupProps {
  title: React.ReactNode
  trailing?: React.ReactNode   // right-aligned accessory in the title row
  children: React.ReactNode    // the grouped Fields
  className?: string
}
export function FieldGroup(props: FieldGroupProps): React.ReactElement
```

