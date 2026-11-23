import Foundation
import AgenticDeveloperHubSDKCore

/// One Terminal Chat as the tools that drive it from outside see it: typed
/// into, waited on, interrupted and read — always through the chat, never
/// the terminal, so each call shows in the chat's transcript.
@MainActor
public protocol TerminalChatDriving: AnyObject {
    /// Whether the chat has a terminal to type into.
    var isConnected: Bool { get }
    func run(_ text: String, settle: Duration, timeout: Duration) async -> String
    func waitForOutput(settle: Duration, timeout: Duration) async -> String
    func interruptAndWait(settle: Duration, timeout: Duration) async -> String
    func screen(lines: Int) -> String?
}

extension TerminalChatSession: TerminalChatDriving {
    public var isConnected: Bool { terminal != nil }
}

/// The Terminal Chats an app has open, as ``TerminalChatDirectoryToolSource``
/// lists and drives them. A protocol so the tools can be exercised against a
/// fake.
@MainActor
public protocol TerminalChatListing: AnyObject {
    /// Every open chat, with the chat to drive, in the order a listing shows.
    var chatEntries: [(chat: TerminalChatControl.Chat, session: any TerminalChatDriving)] { get }
}

/// The Terminal Chats an app has open, by id — what a
/// ``TerminalChatDirectoryToolSource`` answers from.
///
/// A Terminal Chat pane adds itself when it is made and removes itself when
/// it is discarded. Sessions are held weakly besides, so a pane that goes
/// without saying so drops out rather than lingering.
@MainActor
public final class TerminalChatDirectory: TerminalChatListing {

    public struct Listing {
        /// Short and stable: the start of the pane's layout node id, which
        /// survives relaunches.
        public let id: String
        public let project: String
        public let directory: URL
        public let paneNumber: Int
    }

    private struct Entry {
        let listing: Listing
        weak var session: TerminalChatSession?
    }

    private var entries: [String: Entry] = [:]

    public init() {}

    public func add(_ session: TerminalChatSession, as listing: Listing) {
        entries[listing.id] = Entry(listing: listing, session: session)
    }

    public func remove(id: String) {
        entries[id] = nil
    }

    /// The id a pane's chat is listed under.
    public static func chatID(forNode nodeID: UUID) -> String {
        String(nodeID.uuidString.prefix(8)).lowercased()
    }

    public var chatEntries: [(chat: TerminalChatControl.Chat, session: any TerminalChatDriving)] {
        typealias Listed = (chat: TerminalChatControl.Chat, session: any TerminalChatDriving)
        entries = entries.filter { $0.value.session != nil }
        return entries.values.compactMap { entry -> Listed? in
            guard let session = entry.session else { return nil }
            let listing = entry.listing
            // As the connected terminal would show them: a private terminal's
            // home directory or project can name the user, and it conceals
            // them on its screen — so here too. Nothing is listed for one
            // that has not been unlocked yet.
            let presentable = { (text: String) in session.terminal?.presentable(text) ?? text }
            let chat = TerminalChatControl.Chat(
                id: listing.id,
                project: presentable(listing.project),
                directory: presentable(listing.directory.path),
                paneNumber: listing.paneNumber, connected: session.terminal != nil)
            return (chat: chat, session: session)
        }.sorted { ($0.chat.project, $0.chat.paneNumber) < ($1.chat.project, $1.chat.paneNumber) }
    }
}
