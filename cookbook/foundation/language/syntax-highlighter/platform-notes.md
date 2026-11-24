
- **SwiftUI**: Views take `[StyledLine]` and draw runs with their own fonts; the highlighter itself is UI-free.
- **Compose**: The same bundle runs in any JavaScript engine with WebAssembly and promises; the host contract is `ADKHost.grammarText`.
- **React/Web**: The bundle runs as is in a browser; no Swift side is needed.
- **AppKit / UIKit**: JavaScriptCore without `com.apple.security.cs.allow-jit` interprets, correct but slower. The size limits bound the input and the time limits bound the work between regex matches; a single match that backtracks without end is not interrupted, so a hostile grammar's worst case is not bounded.
- **WinUI 3**: A WebView2 host would supply `ADKHost`.

