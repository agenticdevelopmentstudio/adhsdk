#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import AIPluginKit
import Foundation

/// What a daemon tells its ``AccountRouterServer`` about itself. Nothing here
/// names a product: the label, the paths and the Keychain namespace are the
/// hosting daemon's.
public struct AccountRouterConfiguration: Sendable {
    /// The daemon's label (its launchd label, say). Names the router's log
    /// subsystem and its dispatch queues.
    public var label: String
    /// Where routed requests go: the Anthropic API unless a test says otherwise.
    public var upstream: URL
    /// The account fingerprints file the credential fence reads, so a request
    /// carrying another account's token is never re-routed.
    public var fingerprintsPath: String
    /// The directory the model router keeps its template copies in, one JSON
    /// file each.
    public var templateDirectory: URL
    /// A model provider's API key by its Keychain key. Defaults to the toolkit's
    /// shared Keychain namespace, the one a client's AI settings write to.
    public var providerSecret: @Sendable (String) -> String?

    /// The default upstream.
    public static let anthropicAPI = URL(string: "https://api.anthropic.com")!
    /// The template directory's name inside a daemon's data directory.
    public static let templateDirectoryName = ModelRouterTemplateStore.directoryName

    /// - Parameters:
    ///   - label: the daemon's label.
    ///   - dataDirectory: the daemon's data directory; the template copies go in
    ///     its ``templateDirectoryName`` subdirectory unless `templateDirectory`
    ///     says otherwise.
    ///   - fingerprintsPath: the fingerprints file the client publishes.
    public init(
        label: String,
        dataDirectory: URL,
        fingerprintsPath: String,
        upstream: URL = AccountRouterConfiguration.anthropicAPI,
        templateDirectory: URL? = nil,
        providerSecret: @escaping @Sendable (String) -> String? = { KeychainSecretStore().get(forKey: $0) }
    ) {
        self.label = label
        self.upstream = upstream
        self.fingerprintsPath = fingerprintsPath
        self.templateDirectory = templateDirectory
            ?? dataDirectory.appendingPathComponent(Self.templateDirectoryName, isDirectory: true)
        self.providerSecret = providerSecret
    }
}
#endif
