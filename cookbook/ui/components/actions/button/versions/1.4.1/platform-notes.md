
- **SwiftUI**: Start from `Button` with a custom `ButtonStyle`/`PrimitiveButtonStyle`
  per `variant` — SwiftUI's `ButtonStyleConfiguration.isPressed` already reflects
  the real press state natively, so unlike the web the pressed-tracking hooks in
  `button-pressable.tsx` have no equivalent to port; map `size` to explicit
  `frame(minWidth:minHeight:)` values as the counterpart to
  `--adh-button-min-width`/`--adh-button-min-height`.
- **Compose**: Start from `Button`/`OutlinedButton`/`TextButton` per `variant`,
  reading press state from a `MutableInteractionSource`'s `PressInteraction`
  (native, unlike the DOM pointer tracking this component hand-rolls); use
  `Modifier.defaultMinSize()`, set from a `CompositionLocal`, as the counterpart
  to the CSS custom-property floor.
- **React/Web**: This recipe's home platform — `button.tsx` (variants,
  server-safe) plus `button-pressable.tsx` (`"use client"` pointer tracking),
  as documented above.
- **AppKit / UIKit**: Start from `NSButton`/`UIButton`. `UIControl` already
  tracks touch-down/drag-exit/drag-enter natively, so the
  leave-while-held/reenter-while-held semantics this component re-implements
  for the DOM map directly to `.touchDragExit`/`.touchDragEnter` instead of
  custom pointer-event listeners. The 44×44pt Apple HIG minimum this recipe's
  `--adh-button-min-height`/`--adh-button-min-width` vars exist to opt into on
  the web is the default expectation here.
- **WinUI 3**: Start from the `Button` control restyled via a `Style`/
  `ControlTemplate`; Fluent 2's `CommonStates` `VisualStateGroup` already models
  `Pressed`/`PointerOver`/`Normal` (and pointer-exit reverting to `Normal`)
  through the `VisualStateManager`, so the `PointerPressed`/`PointerReleased`/
  `PointerExited`/`PointerEntered` handlers only need to drive state transitions,
  not hand-track a `data-pressed`-equivalent attribute the way `button-pressable.tsx`
  does for the DOM. Fluent 2's control sizing tokens differ from this component's
  Tailwind height scale (`h-6`/`h-7`/`h-8`/`h-9`), so a Windows implementation
  MUST re-derive its size scale from Fluent 2 tokens rather than copying the
  pixel values.

