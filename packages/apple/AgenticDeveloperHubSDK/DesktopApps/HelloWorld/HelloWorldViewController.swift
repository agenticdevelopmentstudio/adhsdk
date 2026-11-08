import AppKit
import Foundation
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKDesktop

/// Hello World's content: the greeting, and the time below it while `showTime` is on.
@MainActor
final class HelloWorldViewController: NSViewController {
    private let settings: DesktopAppSettings
    private let greetingLabel = NSTextField(labelWithString: "")
    private let timeLabel = NSTextField(labelWithString: "")
    private var clock: Timer?
    /// Keeps the settings subscription alive; typed loosely so this file needs no Combine import.
    private var subscription: AnyObject?
    /// The menu targets for this window's menus; menu items hold their target weakly.
    var menuTargets: [ClosureMenuItemTarget] = []

    /// Uppercases the greeting. Per window.
    var isUppercase = false {
        didSet { refreshGreeting() }
    }

    var displayedGreeting: String { greetingLabel.stringValue }
    var isTimeHidden: Bool { timeLabel.isHidden }
    var isClockRunning: Bool { clock != nil }

    init(settings: DesktopAppSettings) {
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        greetingLabel.font = .systemFont(ofSize: 34, weight: .semibold)
        greetingLabel.alignment = .center
        greetingLabel.lineBreakMode = .byTruncatingTail
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 17, weight: .regular)
        timeLabel.textColor = .secondaryLabelColor
        timeLabel.alignment = .center

        let stack = NSStackView(views: [greetingLabel, timeLabel])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let root = NSView()
        root.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: root.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: root.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -16)
        ])
        view = root

        refreshGreeting()
        refreshTime()
        subscription = settings.changes.sink { [weak self] _ in
            MainActor.assumeIsolated {
                self?.refreshGreeting()
                self?.refreshTime()
            }
        }
        startClock()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        if clock == nil { startClock() }
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        stopClock()
    }

    func stopClock() {
        clock?.invalidate()
        clock = nil
    }

    private func startClock() {
        stopClock()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshTime() }
        }
        // `.common`, so the clock keeps ticking during menu tracking and live resize.
        RunLoop.main.add(timer, forMode: .common)
        clock = timer
    }

    private func refreshGreeting() {
        guard isViewLoaded else { return }
        let greeting = settings.string("greeting")
        greetingLabel.stringValue = isUppercase ? greeting.uppercased() : greeting
    }

    private func refreshTime() {
        timeLabel.isHidden = !settings.bool("showTime")
        timeLabel.stringValue = Date.now.formatted(date: .omitted, time: .standard)
    }
}
