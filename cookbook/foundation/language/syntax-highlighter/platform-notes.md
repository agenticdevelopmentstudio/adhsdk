
- **SwiftUI**: Views take `[StyledLine]` and draw runs with their own fonts; the highlighter itself is UI-free.
- **Compose**: The same bundle runs in any JavaScript engine with WebAssembly and promises; the host contract is `ADKHost.grammarText`.
- **React/Web**: The bundle runs as is in a browser; no Swift side is needed.
- **AppKit / UIKit**: JavaScriptCore without `com.apple.security.cs.allow-jit` interprets, correct but slower; the limits keep the worst case bounded.
- **WinUI 3**: A WebView2 host would supply `ADKHost`.

