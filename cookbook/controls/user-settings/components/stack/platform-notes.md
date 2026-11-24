
- **SwiftUI**: Implement using the native `VStack(alignment:spacing:)` and `HStack(alignment:spacing:)` initializers. Map `gap` to the initializer's `spacing` parameter — SwiftUI has no `.spacing()` modifier. Map `align` to the initializer's `alignment` parameter. SwiftUI's `VStack`/`HStack` have no `justifyContent` equivalent; approximate `justify` with `Spacer()` views placed between or around children (see Design Decisions for which control wins when a platform can't represent both `gap` and `justify` independently).

  | `justify` | SwiftUI approximation |
  |-----------|-----------------------|
  | `flex-start` | `Spacer()` after the children |
  | `center` | `Spacer()` before and after the children |
  | `flex-end` | `Spacer()` before the children |
  | `space-between` | `Spacer()` between each pair of children |
  | `space-around` | `Spacer()` between each pair of children and at the ends (closest available; the ends are not half-size) |
  | `space-evenly` | `Spacer()` between each pair of children and at both ends |
- **Compose (Android)**: Implement using Jetpack Compose's `Column` (for VStack) and `Row` (for HStack) composables. Map `gap` to the `verticalArrangement` (Column) or `horizontalArrangement` (Row) parameter, using `Arrangement.spacedBy()`. Map `align` to the `horizontalAlignment` (Column) or `verticalAlignment` (Row) parameter — this is the cross-axis alignment, opposite of the axis `gap` uses. `Arrangement.spacedBy()` (from `gap`) and `Arrangement.SpaceBetween` (from `justify`) both set the same `Arrangement` parameter and cannot be applied together; per Design Decisions, `gap` takes precedence and `justify` is dropped when both are set.

  | `justify` | `Arrangement` (Column / Row) |
  |-----------|------------------------------|
  | `flex-start` | `Arrangement.Top` / `Arrangement.Start` |
  | `center` | `Arrangement.Center` |
  | `flex-end` | `Arrangement.Bottom` / `Arrangement.End` |
  | `space-between` | `Arrangement.SpaceBetween` |
  | `space-around` | `Arrangement.SpaceAround` |
  | `space-evenly` | `Arrangement.SpaceEvenly` |
- **React/Web**: Implemented as functional components in `Stack.tsx`. VStack renders a div with `aws-stack--v` class; HStack renders a div with `aws-stack--h` class. Gap conversion from number to pixel string is handled by the `gapValue()` utility. Styles are merged inline using spread syntax, with the `style` prop taking precedence. Classes are filtered and joined using a simple boolean filter to avoid empty strings. Only the props defined on `StackProps` are read; the components never spread additional rest props onto the root element, so `id`, `role`, and `aria-*` are never forwarded.
- **AppKit / UIKit**: Use `NSStackView` (macOS) or `UIStackView` (iOS) as the container. Set the `axis` property to `.vertical` for VStack or `.horizontal` for HStack. Map `gap` to the `spacing` property; map `align` to the `alignment` property; map `justify` to the `distribution` property (using `.fillEqually`, `.equalCentering`, or `.fill` as appropriate). A `distribution` other than `.fill` can override the visual effect of `spacing`, so per Design Decisions, `gap` (spacing) takes precedence and `justify` is approximated with the closest available distribution.

  | `justify` | `NSStackView` / `UIStackView` |
  |-----------|-------------------------------|
  | `flex-start`, `center`, `flex-end` | `NSStackView`: `.gravityAreas` with the `.leading`/`.top`, `.center` or `.trailing`/`.bottom` gravity. `UIStackView`: `.fill` plus flexible spacer views before and/or after the children. |
  | `space-between` | `.equalSpacing` |
  | `space-around` | `.equalCentering` (closest available) |
  | `space-evenly` | `.equalSpacing` (closest available; no exact equivalent) |
- **WinUI 3**: Implement using XAML `StackPanel`. Set `Orientation="Vertical"` for VStack or `Orientation="Horizontal"` for HStack. Map `gap` to the `Spacing` property, a `double` (not an integer). `StackPanel` has no `justifyContent` equivalent — there is no native way to distribute or justify children within it; where `justify` must be approximated, use a `Grid` with star-sized (`*`) rows or columns instead. A `Grid` replaces the `StackPanel` `Spacing`, so per Design Decisions `gap` takes precedence and `justify` is dropped when both are set. Map `align` to the children's `HorizontalAlignment` (VStack) or `VerticalAlignment` (HStack): `flex-start` to `Left`/`Top`, `center` to `Center`, `flex-end` to `Right`/`Bottom`, `stretch` to `Stretch`. Custom classes are not applicable to `StackPanel`; apply styling via a XAML `Style` resource (there is no "CSS-in-XAML").
