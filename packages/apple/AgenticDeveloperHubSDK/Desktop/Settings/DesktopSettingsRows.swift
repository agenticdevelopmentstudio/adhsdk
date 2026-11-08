import AppKit

/// Layout shared by the Desktop's settings forms: labeled rows in a padded vertical stack.
@MainActor
enum DesktopSettingsRows {
    /// A label to the left of a control. A `labelWidth` right-aligns the label in a fixed column.
    static func labeledRow(_ title: String, _ control: NSView, labelWidth: CGFloat? = nil) -> NSStackView {
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 13, weight: .medium)
        if let labelWidth {
            label.alignment = .right
            label.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
        }
        let row = NSStackView(views: [label, control])
        row.spacing = 12
        if labelWidth != nil { row.alignment = .firstBaseline }
        return row
    }

    /// Rows stacked vertically inside a root view, pinned to its top-leading corner.
    static func formView(_ rows: [NSView]) -> NSView {
        let stack = NSStackView(views: rows)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        let root = NSView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: root.topAnchor),
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: root.bottomAnchor)
        ])
        return root
    }
}
