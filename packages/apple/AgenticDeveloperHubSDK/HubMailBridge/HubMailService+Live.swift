import Foundation
import AgenticDeveloperHubAuth
import AgenticDeveloperHubClient
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKHubAuth
import AgenticDeveloperHubSDKHubMail

/// The hub account and the mail it signs in to, sharing one session.
///
/// Show `account` in the accounts settings; read mail through
/// `service.client`. Call `start()` at launch when the app reads hub mail, so
/// a stored login connects without the user opening Settings.
@MainActor
public struct LiveHubMail {
    public let account: HubAccount
    public let service: HubMailService

    public func start() {
        account.restore()
    }
}

extension HubMailService {

    /// A live session over direct HTTPS (the same Keychain login
    /// `HubAccount.live` uses), with the mirror at `databaseURL`.
    ///
    /// The database opens on the first sign-in and stays open, so signing
    /// out and back in reuses it. Pulls authenticate with the stored session;
    /// label changes go through the hub client, whose middleware refreshes
    /// an expired token.
    public static func live(
        databaseURL: URL,
        deviceId: String,
        syncInterval: TimeInterval? = 300,
        sessionStore: any SessionStore = KeychainSessionStore(keyPrefix: "adh.api"),
        configuration: SignInConfiguration = .fromBundle()
    ) -> LiveHubMail {
        let environment = HubEnvironment.direct(sessionStore: sessionStore)
        let session = SessionController(environment: environment, configuration: configuration)
        let opener = DatabaseOpener(url: databaseURL)
        let service = HubMailService(syncInterval: syncInterval) {
            let sync = try HubMailSync(
                database: try opener.database(),
                api: ADHSyncAPI(credentials: sessionStore),
                deviceId: deviceId
            )
            let writeLabels: @Sendable (HubMailLabelWrite) async throws -> Void = { write in
                let api = await MainActor.run { environment.client.api }
                try await HubMailBridge.labelWriter(sender: HubMailSender(client: api))(write)
            }
            return Connection(sync: sync, writeLabels: writeLabels)
        }
        // Set before HubAccount wraps the session: the account chains onto
        // this handler rather than replacing it.
        session.onChange = { [weak service] state in
            guard let service else { return }
            Task { await service.follow(state) }
        }
        return LiveHubMail(account: HubAccount(session: session), service: service)
    }

    /// Opens on sign-in, purges on sign-out. `.restoring` and `.error` leave
    /// the mirror as it is: neither says who the user is.
    public func follow(_ state: SessionState) async {
        switch state {
        case .signedIn: await signedIn()
        case .signedOut: await signedOut()
        case .restoring, .error: break
        }
    }
}

/// Opens the mirror's database once, creating its folder.
@MainActor
private final class DatabaseOpener {
    private let url: URL
    private var opened: BoundedDatabase?

    init(url: URL) {
        self.url = url
    }

    func database() throws -> BoundedDatabase {
        if let opened { return opened }
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let database = try BoundedDatabase(path: url.path)
        opened = database
        return database
    }
}
