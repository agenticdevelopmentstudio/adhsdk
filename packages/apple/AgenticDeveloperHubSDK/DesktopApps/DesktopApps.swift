import AgenticDeveloperHubSDKDesktop
import AgenticDeveloperHubSDKIntegrations

/// The Desktop's built-in Apps.
@MainActor
public enum DesktopApps {
    /// A registry holding Hello World, then Email.
    public static func makeRegistry(mailClient: MailClient) -> DesktopAppRegistry {
        let registry = DesktopAppRegistry()
        registry.register(HelloWorldApp())
        registry.register(EmailApp(client: mailClient))
        return registry
    }
}
