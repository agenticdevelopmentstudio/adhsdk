import AppKit

/// The About window's content: icon, name, version, summary, attribution, link, binding.
@MainActor
final class DesktopAboutViewController: NSViewController {
    private static let iconSize: CGFloat = 128
    private let app: DesktopApp

    init(app: DesktopApp) {
        self.app = app
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        let descriptor = app.descriptor
        let icon = NSImageView(image: DesktopAppIconRenderer.image(for: app, pointSize: Self.iconSize))
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.widthAnchor.constraint(equalToConstant: Self.iconSize).isActive = true
        icon.heightAnchor.constraint(equalToConstant: Self.iconSize).isActive = true

        let name = Self.label(descriptor.displayName, font: .boldSystemFont(ofSize: 20))
        var views: [NSView] = [
            icon, name,
            Self.label("Version \(descriptor.version)", color: .secondaryLabelColor),
            Self.label(descriptor.summary),
            Self.label(descriptor.attribution.author),
            Self.label(descriptor.attribution.copyright, color: .secondaryLabelColor)
        ]
        if let url = descriptor.attribution.url {
            views.append(Self.linkLabel(url))
        }
        if let binding = descriptor.integration {
            views.append(Self.label(
                "Integration: \(binding.serviceType) (\(binding.provider ?? "any provider"))",
                color: .secondaryLabelColor
            ))
        }
        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 20, bottom: 20, right: 20)

        let root = NSView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: root.topAnchor),
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor)
        ])
        view = root
    }

    private static func label(
        _ text: String,
        font: NSFont = .systemFont(ofSize: 13),
        color: NSColor = .labelColor
    ) -> NSTextField {
        let field = NSTextField(wrappingLabelWithString: text)
        field.font = font
        field.textColor = color
        field.alignment = .center
        return field
    }

    private static func linkLabel(_ url: URL) -> NSTextField {
        let field = NSTextField(labelWithString: "")
        field.allowsEditingTextAttributes = true
        field.isSelectable = true
        field.attributedStringValue = NSAttributedString(string: url.absoluteString, attributes: [
            .link: url,
            .font: NSFont.systemFont(ofSize: 13)
        ])
        return field
    }
}
