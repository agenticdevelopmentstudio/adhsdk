
- **SwiftUI**: Host the AppKit controller in an `NSViewControllerRepresentable`; a `LazyVStack` of `Text` rows would not reach 100 000 rows smoothly.
- **Compose**: A `LazyColumn` over the same row model gives the same virtualisation.
- **React/Web**: A windowed list (fixed row height) over the same row model.
- **AppKit / UIKit**: AppKit: an `NSScrollView` over a flipped document view drawing with Core Text. UIKit: a `UIScrollView` with the same drawing.
- **WinUI 3**: An `ItemsRepeater` with a fixed-height virtualising layout.

