import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS
import os

/// A round avatar (recipe `ui/components/display/avatar`): the picture when it
/// loads, the initials on a circle coloured from `seed` until then and whenever
/// it does not. Content without an `imageURL` is never fetched.
///
/// There is no cache of its own: the default fetch goes through
/// `URLSession.shared`, whose HTTP cache follows the server's caching
/// headers, so a picture replaced at the same URL is picked up when they say.
@MainActor
public final class AvatarView: NSView {
    /// Fetches a picture's bytes and the response that came with them.
    public typealias Fetch = @Sendable (URL) async throws -> (Data, URLResponse)

    public let side: CGFloat

    private let circle = NSView()
    /// The initials. A plain label rather than a `ThemedLabel`: both its ink
    /// and its size depend on this view (the circle's lane, the side), so
    /// `paintCircle()` sets them on every theme change.
    let initialsLabel = NSTextField(labelWithString: "")
    private let imageView = NSImageView()
    private let fetch: Fetch
    private var palette: SemanticPalette = ThemePaletteObserver.currentPalette
    /// The load in flight, if any; nil once it settles, so a later showing can retry.
    private(set) var loadTask: Task<Void, Never>?

    public var content: AvatarContent? {
        didSet { if content != oldValue { render() } }
    }

    /// True while the picture, not the initials, is on screen.
    var showsPicture: Bool { !imageView.isHidden && imageView.image != nil }

    /// The initials currently on the circle.
    var initials: String { initialsLabel.stringValue }

    public init(side: CGFloat = 48, fetch: @escaping Fetch = { try await URLSession.shared.data(from: $0) }) {
        self.side = side
        self.fetch = fetch
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setAccessibilityIdentifier("avatar")
        setAccessibilityRole(.image)
        for sub in [circle, imageView] {
            sub.translatesAutoresizingMaskIntoConstraints = false
            sub.wantsLayer = true
            sub.layer?.cornerRadius = side / 2
            sub.layer?.masksToBounds = true
            addSubview(sub)
        }
        initialsLabel.alignment = .center
        initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        circle.addSubview(initialsLabel)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: side),
            heightAnchor.constraint(equalToConstant: side),
            circle.leadingAnchor.constraint(equalTo: leadingAnchor),
            circle.trailingAnchor.constraint(equalTo: trailingAnchor),
            circle.topAnchor.constraint(equalTo: topAnchor),
            circle.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            initialsLabel.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: circle.centerYAnchor)
        ])
        observeTheme { view, palette in
            view.palette = palette
            view.paintCircle()
        }
        render()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    /// The lane-palette index for `seed`: FNV-1a 64 over its UTF-8 bytes, so
    /// one person keeps one colour across launches (`hashValue` is seeded
    /// per process).
    static func colourIndex(seed: String) -> Int {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in seed.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return Int(hash % UInt64(SemanticPalette.laneCount))
    }

    /// The initials' point size as a share of the side: two wide capitals
    /// ("MW") stay inside the circle from a 20 pt table row up to the 48 pt
    /// Accounts header.
    static let initialsScale: CGFloat = 0.4

    private func paintCircle() {
        let index = Self.colourIndex(seed: content?.seed ?? "")
        circle.layer?.backgroundColor = NSColor(palette.laneColor(index)).cgColor
        initialsLabel.textColor = NSColor(palette.laneTextColor(index))
        // The theme's heading family, semibold, at a size that follows the side.
        var style = palette.theme.typography.style(.heading)
        style.weight = .semibold
        initialsLabel.font = style.nsFont(scaledSize: side * Self.initialsScale)
    }

    private func render() {
        loadTask?.cancel()
        loadTask = nil
        imageView.image = nil
        imageView.isHidden = true
        initialsLabel.stringValue = content?.initials ?? ""
        setAccessibilityLabel(content.map { "Avatar for \($0.name)" })
        paintCircle()
        load()
    }

    /// Showing the view again retries a picture that has not loaded, such as
    /// one that failed while the Mac was offline.
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil, !showsPicture { load() }
    }

    private func load() {
        guard loadTask == nil, let url = content?.imageURL else { return }
        let fetch = self.fetch
        loadTask = Task { [weak self] in
            let image = await Self.picture(at: url, fetch: fetch)
            // A cancelled load was replaced by render(), which owns loadTask now.
            guard !Task.isCancelled, let self else { return }
            self.loadTask = nil
            guard let image else { return }
            self.imageView.image = image
            self.imageView.isHidden = false
        }
    }

    /// The picture at `url`, or nil, logged, when the fetch fails, the server
    /// answers with anything but a 2xx, or the bytes are not an image.
    private static func picture(at url: URL, fetch: Fetch) async -> NSImage? {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await fetch(url)
        } catch {
            if !(error is CancellationError) {
                logger.debug("avatar load failed: \(error.localizedDescription, privacy: .public)")
            }
            return nil
        }
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            logger.debug("avatar load got HTTP \(http.statusCode, privacy: .public)")
            return nil
        }
        guard let image = NSImage(data: data) else {
            logger.debug("avatar data is not an image (\(data.count, privacy: .public) bytes)")
            return nil
        }
        return image
    }
}

extension AvatarView: Loggable {
    public static nonisolated let logger = makeLogger()
}
