import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS

extension ComposableSettings {

    /// Root container for a panel. Hosts a vertical stack of `GroupView` cards,
    /// spaced apart inside the panel's content area.
    @MainActor
    open class PanelView: NSView, SettingsViewProtocol {

        private let stackView = NSStackView()
        private var themeObserver: ThemePaletteObserver?
        /// The groups each tab of `addTabs` shows, by segment.
        private var tabGroups: [[GroupView]] = []
        /// The control `addTabs` put at the top, if any.
        public private(set) var tabControl: NSSegmentedControl?

        public convenience init() {
            self.init(frame: .zero)
        }

        public override init(frame frameRect: NSRect) {
            super.init(frame: .zero)
            self.translatesAutoresizingMaskIntoConstraints = false
            self.wantsLayer = true

            self.stackView.orientation = .vertical
            self.stackView.spacing = SettingsLayout.default[.groupSpacing]
            self.stackView.alignment = .leading
            self.stackView.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(self.stackView)

            let inset = SettingsLayout.default[.panelInset]
            NSLayoutConstraint.activate([
                self.stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: inset),
                self.stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: inset),
                self.stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -inset),
                self.stackView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -inset)
            ])

            themeObserver = ThemePaletteObserver(host: self) { [weak self] palette in
                // The same ground as the sidebar and the window: the cards are
                // what stand out here, and a panel-shaped patch of a second
                // near-identical colour behind them only reads as a misprint.
                self?.layer?.backgroundColor = palette.windowBackgroundColor.cgColor
            }
        }

        public required init?(coder: NSCoder) {
            fatalError("not overridden")
        }

        /// Groups are separated by the stack's own spacing, not a rule: each one
        /// is a card with its own edges, and a divider between two cards reads
        /// as a third thing floating in the gutter.
        public func addGroup(_ group: GroupView) {
            self.stackView.addArrangedSubview(group)
        }

        /// Adds a heading over the groups that follow it.
        ///
        /// The gap above a heading is wider than the gap between two cards,
        /// because that gap is what says the heading belongs to what comes
        /// *after* it — at the stack's own spacing it reads as a caption
        /// trailing the card above.
        @discardableResult
        public func addHeading(_ title: String, caption: String? = nil) -> PanelHeadingView {
            let heading = PanelHeadingView(title: title, caption: caption)
            if let last = self.stackView.arrangedSubviews.last {
                self.stackView.setCustomSpacing(
                    SettingsLayout.default[.groupSpacing] * 1.5, after: last)
            }
            self.stackView.addArrangedSubview(heading)
            heading.widthAnchor.constraint(equalTo: self.stackView.widthAnchor).isActive = true
            return heading
        }

        /// One tab of `addTabs`: its title and the groups it shows.
        public struct Tab {
            public let title: String
            public let groups: [GroupView]

            public init(_ title: String, _ groups: [GroupView]) {
                self.title = title
                self.groups = groups
            }
        }

        /// Puts a segmented control, centred, at the top of the panel and adds
        /// every tab's groups below it, showing only the selected tab's. The
        /// stack detaches hidden views, so a hidden tab takes no room.
        /// - Parameters:
        ///   - identifier: the control's accessibility identifier.
        @discardableResult
        public func addTabs(_ tabs: [Tab], identifier: String? = nil) -> NSSegmentedControl {
            let control = NSSegmentedControl(
                labels: tabs.map(\.title), trackingMode: .selectOne,
                target: self, action: #selector(tabChanged(_:))
            )
            control.selectedSegment = 0
            control.translatesAutoresizingMaskIntoConstraints = false
            if let identifier { control.setAccessibilityIdentifier(identifier) }
            let bar = NSView()
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.addSubview(control)
            NSLayoutConstraint.activate([
                control.topAnchor.constraint(equalTo: bar.topAnchor),
                control.bottomAnchor.constraint(equalTo: bar.bottomAnchor),
                control.centerXAnchor.constraint(equalTo: bar.centerXAnchor)
            ])
            self.stackView.addArrangedSubview(bar)
            bar.widthAnchor.constraint(equalTo: self.stackView.widthAnchor).isActive = true
            tabGroups = tabs.map(\.groups)
            tabControl = control
            for group in tabs.flatMap(\.groups) { addGroup(group) }
            showTab(0)
            return control
        }

        /// Shows tab `index`'s groups and hides the rest.
        public func showTab(_ index: Int) {
            guard tabGroups.indices.contains(index) else { return }
            tabControl?.selectedSegment = index
            for (tab, groups) in tabGroups.enumerated() {
                for group in groups { group.isHidden = tab != index }
            }
        }

        @objc private func tabChanged(_ sender: NSSegmentedControl) {
            showTab(sender.selectedSegment)
        }

        /// Takes away every group and heading, for a panel that draws itself
        /// from a model that can change after it was first built.
        public func removeAllContent() {
            for view in self.stackView.arrangedSubviews {
                self.stackView.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
        }

    }
}
