import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKCore

/// Counts fetches, and answers each from the list of replies in turn (the last
/// one repeats).
private final class Server: @unchecked Sendable {
    enum Reply { case status(Int, Data), offline }
    private let lock = NSLock()
    private var replies: [Reply]
    private var count = 0
    var calls: Int { lock.withLock { count } }

    init(_ replies: Reply...) { self.replies = replies }

    func fetch(_ url: URL) throws -> (Data, URLResponse) {
        let reply = lock.withLock {
            count += 1
            return replies.count > 1 ? replies.removeFirst() : replies[0]
        }
        switch reply {
        case .offline:
            throw URLError(.notConnectedToInternet)
        case .status(let code, let data):
            return (data, HTTPURLResponse(url: url, statusCode: code, httpVersion: nil, headerFields: nil)!)
        }
    }
}

private let picture: Data = {
    let image = NSImage(size: NSSize(width: 2, height: 2))
    image.lockFocus()
    NSColor.red.drawSwatch(in: NSRect(x: 0, y: 0, width: 2, height: 2))
    image.unlockFocus()
    return image.tiffRepresentation!
}()

private let ada = AvatarContent(name: "Ada Lovelace", seed: "ada@x.y", imageURL: URL(string: "https://x.y/a.png"))

@Suite("AvatarView")
@MainActor
struct AvatarViewTests {
    private func make(_ server: Server, side: CGFloat = 48) -> AvatarView {
        AvatarView(side: side, fetch: { try server.fetch($0) })
    }

    private func show(_ view: AvatarView, content: AvatarContent = ada) async {
        view.content = content
        await view.loadTask?.value
    }

    @Test("a picture the server sends replaces the initials")
    func loads() async {
        let view = make(Server(.status(200, picture)))
        await show(view)
        #expect(view.showsPicture)
    }

    @Test("an error page is never shown as the picture, even one that decodes")
    func refusesNon2xx() async {
        let view = make(Server(.status(404, picture)))
        await show(view)
        #expect(!view.showsPicture)
    }

    @Test("bytes that are not an image leave the initials up")
    func refusesUndecodable() async {
        let view = make(Server(.status(200, Data("<html>".utf8))))
        await show(view)
        #expect(!view.showsPicture)
    }

    @Test("a picture that failed to load is fetched again when the view is shown")
    func retriesWhenShown() async {
        let server = Server(.offline, .status(200, picture))
        let view = make(server)
        await show(view)
        #expect(!view.showsPicture)

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
                              styleMask: .titled, backing: .buffered, defer: true)
        window.contentView?.addSubview(view)
        await view.loadTask?.value

        #expect(server.calls == 2)
        #expect(view.showsPicture)
    }

    @Test("showing a loaded picture again does not fetch it again")
    func noRefetchWhenLoaded() async {
        let server = Server(.status(200, picture))
        let view = make(server)
        await show(view)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
                              styleMask: .titled, backing: .buffered, defer: true)
        window.contentView?.addSubview(view)
        #expect(view.loadTask == nil)
        #expect(server.calls == 1)
    }

    @Test("content without an image URL shows initials and fetches nothing, even when shown")
    func noFetchWithoutImageURL() async {
        let server = Server(.status(200, picture))
        let view = make(server)
        await show(view, content: AvatarContent(name: "Zoe", seed: "z@x.y", imageURL: nil))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
                              styleMask: .titled, backing: .buffered, defer: true)
        window.contentView?.addSubview(view)
        #expect(view.loadTask == nil)
        #expect(!view.showsPicture)
        #expect(view.initials == "Z")
        #expect(server.calls == 0)
    }

    @Test("initials: first letters of the first two words, else the seed's first letter, else ?")
    func initials() {
        #expect(AvatarContent(name: "ada lovelace byron", seed: "a@b.c", imageURL: nil).initials == "AL")
        #expect(AvatarContent(name: "   ", seed: "zed@b.c", imageURL: nil).initials == "Z")
        #expect(AvatarContent(name: "", seed: "", imageURL: nil).initials == "?")
    }

    @Test("the circle's palette index is a stable FNV-1a hash of the seed, modulo the lane palette")
    func stableColourIndex() {
        #expect(SemanticPalette.laneCount == 12)
        #expect(AvatarView.colourIndex(seed: "") == 5)
        #expect(AvatarView.colourIndex(seed: "ada@x.y") == 6)
        #expect(AvatarView.colourIndex(seed: "b") == 1)
    }

    @Test("the side is configurable and the view is that square")
    func sideIsConfigurable() {
        let view = make(Server(.status(200, picture)), side: 20)
        #expect(view.side == 20)
        #expect(view.fittingSize == NSSize(width: 20, height: 20))
        #expect(AvatarView().side == 48)
    }

    @Test("carries an accessibility identifier and labels the person")
    func accessibility() async {
        let view = make(Server(.status(404, Data())))
        await show(view)
        #expect(view.accessibilityIdentifier() == "avatar")
        #expect(view.accessibilityLabel() == "Avatar for Ada Lovelace")
    }
}
