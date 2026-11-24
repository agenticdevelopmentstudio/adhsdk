
- **SwiftUI**: Not applicable: The resources hold no Swift code; the toolkit's syntax highlighter loads `highlighter.js` and `onig.wasm` into a `JSContext` and supplies `ADKHost.grammarText`.
- **Compose**: The same tree runs in any JavaScript engine with WebAssembly; on Android a WebView or J2V8 host would supply `ADKHost`.
- **React/Web**: The bundle runs as is in a browser or Node (`vm.runInThisContext`); the README's smoke test is that host.
- **AppKit / UIKit**: The app copies the directory into `Contents/Resources/TextMate/`; JavaScriptCore runs the WASM interpreted without `com.apple.security.cs.allow-jit`, correct but 10-20 times slower.
- **WinUI 3**: A WebView2 host would supply `ADKHost`; nothing in the tree is Apple-specific.

