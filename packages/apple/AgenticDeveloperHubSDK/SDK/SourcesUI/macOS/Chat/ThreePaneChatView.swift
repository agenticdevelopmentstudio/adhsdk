import AppKit
import AgenticDeveloperHubSDK

/// Web's three-pane mode — topics list, transcript, detail pane, with drawn
/// connectors between them — is not ported yet. Deferred deliberately; this
/// stub exists so `PersonaChatMode` is total and hosts can compile against the
/// full enum today.
///
/// TODO: port `modes/ThreePaneChat.tsx` and its four subcomponents —
/// `TopicsPane`, `DetailPane`, `PanelStack`, `ConnectorSVG` — plus
/// `css/modes/three-pane.css`. Until then this renders the inline mode.
@MainActor
public final class ThreePaneChatView: NSView {

    private let inline: InlineChatView

    public init(viewModel: any ChatViewModel, localParticipantID: String) {
        inline = InlineChatView(viewModel: viewModel, localParticipantID: localParticipantID)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        inline.translatesAutoresizingMaskIntoConstraints = false
        addSubview(inline)
        NSLayoutConstraint.activate([
            inline.topAnchor.constraint(equalTo: topAnchor),
            inline.leadingAnchor.constraint(equalTo: leadingAnchor),
            inline.trailingAnchor.constraint(equalTo: trailingAnchor),
            inline.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}
