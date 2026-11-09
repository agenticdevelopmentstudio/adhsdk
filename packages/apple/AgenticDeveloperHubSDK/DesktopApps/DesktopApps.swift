import AgenticDeveloperHubSDKDesktop
import AgenticDeveloperHubSDKIntegrations

/// The Desktop's built-in Apps.
@MainActor
public enum DesktopApps {
    /// A registry holding Hello World, Email, then Settings, which edits `settings`.
    public static func makeRegistry(
        mailClient: MailClient, settings: DesktopSettings = .shared
    ) -> DesktopAppRegistry {
        let registry = DesktopAppRegistry()
        registry.register(HelloWorldApp())
        registry.register(EmailApp(client: mailClient))
        registry.register(DesktopSettingsApp(settings: settings))
        return registry
    }
}
