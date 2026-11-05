import SwiftUI

@main
struct AgenticDeveloperHubSDKSampleApp: App {
    #if os(macOS)
    @Environment(\.openWindow) var openWindow
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .windowList) {
                Button("Open API Documentation") {
                    openWindow(id: "api-viewer")
                }
                .keyboardShortcut("a", modifiers: [.command, .option])
            }
        }
        #endif

        #if os(macOS)
        Window("OpenAPI Viewer", id: "api-viewer") {
            OpenAPIViewerWindow()
        }
        #endif
    }
}
