
- **Swift / SwiftUI**: Not applicable until a SwiftUI port; translate ProgressSummary as a stack of `Text` and `ProgressView`/`Image(systemName:)` views.
- **Kotlin / Compose**: Not applicable until a Compose port; use `Column`, `Text`, `LinearProgressIndicator`.
- **React / Web (TypeScript)**: Exported from `@adh-sdk/ui` (`@adh-sdk/ui/blocks/progress-summary`). Counts come from `countProgress` in `@adh-sdk/ui/lib/progress-count`.
- **AppKit / UIKit**: Not applicable until a native port; use `NSStackView`/`UIStackView` with `NSProgressIndicator`/`UIProgressView`.
- **WinUI 3**: Not applicable until a WinUI port; use `StackPanel`, `TextBlock`, `ProgressBar`.
