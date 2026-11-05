import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(iOS)
        TabView {
            HelloView()
                .tabItem { Label("Hello", systemImage: "person.2.wave.2.fill") }
            MarkdownScreen()
                .tabItem { Label("Markdown", systemImage: "doc.richtext") }
        }
        #else
        HelloView()
        #endif
    }
}

/// The original greeting, unchanged — extracted so iOS can put it in a tab.
private struct HelloView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.wave.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Hello, World!")
                .font(.largeTitle)
            Text("Agentic Developer Hub SDK")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(minWidth: 320, minHeight: 240)
    }
}

#Preview {
    ContentView()
}
