import AgenticDeveloperHubClient
import AgenticDeveloperHubSDKPermissions

/// The grants the hub service itself needs — one Keychain entry, where the
/// session lives. A host lists these in its permissions panel and walkthrough
/// instead of the toolkit's default set, which names grants the hub never
/// asks for. macOS only: `AgenticDeveloperHubSDKPermissions` is a macOS framework.
public enum HubPermissions {
    public static let required: [AgenticDeveloperHubSDKPermissions.Permission] = [
        .keychain(service: HubKeychainHelper.service)
    ]
}
