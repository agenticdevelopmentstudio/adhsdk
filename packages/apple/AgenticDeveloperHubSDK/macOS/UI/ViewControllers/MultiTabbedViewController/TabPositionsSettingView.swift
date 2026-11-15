import AppKit
import AgenticDeveloperHubSDKCore

/// A "Tab position" settings row: one switch per edge (Top, Left, Right,
/// Bottom) over a `TabPositions` value read and written through closures, so
/// the same row serves the app-wide setting (System ▸ General) and a browser
/// pane's override.
///
/// Turning off the last enabled edge is refused: the write is dropped and the
/// switch re-reads the value, which still has the edge on
/// (`edges-never-empty`).
@MainActor
public final class TabPositionsSettingView: NSView, SettingsViewProtocol {

    /// The switch rows, by edge.
    public private(set) var checkboxes: [Edge: ComposableSettings.CheckboxView] = [:]
    private var models: [ComposableSettings.ViewModel<Bool>] = []

    /// - Parameters:
    ///   - get: The positions the row shows.
    ///   - set: Stores new positions; never handed an empty set.
    ///   - identifierPrefix: Each switch's accessibility identifier is this
    ///     plus `.<edge>` (`settings.general.tab-position.top`).
    public init(
        title: String = "Tab position",
        get: @escaping () -> TabPositions,
        set: @escaping (TabPositions) -> Void,
        identifierPrefix: String
    ) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        var rows: [NSView] = [ComposableSettings.makeRowLabel(title)]
        for edge in TabPositions.primaryOrder {
            let model = ComposableSettings.ViewModel<Bool>(
                title: edge.displayName,
                get: { get().edges.contains(edge) },
                set: { enabled in
                    // `nil` is the last edge going off: nothing is stored, and
                    // the switch's change callback re-reads it as still on.
                    guard let next = get().setting(edge, enabled: enabled) else { return }
                    set(next)
                }
            )
            let checkbox = ComposableSettings.CheckboxView(with: model)
            _ = checkbox.toggle.accessibilityID("\(identifierPrefix).\(edge.rawValue)")
            checkboxes[edge] = checkbox
            models.append(model)
            rows.append(checkbox)
        }

        let stack = NSStackView(views: rows)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = ComposableSettings.SettingsLayout.default[.rowSpacing]
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        for checkbox in checkboxes.values {
            checkbox.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Re-reads the value into every switch, after it changed elsewhere (the
    /// View menu, an override removed).
    public func refresh() {
        models.forEach { $0.revert() }
    }
}
