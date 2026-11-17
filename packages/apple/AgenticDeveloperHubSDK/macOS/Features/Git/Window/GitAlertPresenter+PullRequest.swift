import AppKit
import AgenticDeveloperHubSDKCore

/// What the new pull request form answers: what `gh pr create` is given.
public struct GitPullRequestDraft: Equatable, Sendable {
    public var title: String
    public var body: String
    /// The branch to merge into; nil leaves it to `gh`, which picks the default branch.
    public var base: String?
    public var draft: Bool

    public init(title: String, body: String, base: String?, draft: Bool) {
        self.title = title
        self.body = body
        self.base = base
        self.draft = draft
    }
}

extension GitAlertPresenter {

    /// The new pull request form as a sheet (recipe `workspace/git/git-views`, "Pull
    /// requests"): title, body, base and Draft. Create answers the form's values, Cancel
    /// and the window closing under it nil. The form is the confirmation.
    public func createPullRequest(head: String, defaultTitle: String, defaultBody: String,
                                  bases: [String]) async -> GitPullRequestDraft? {
        let form = Self.pullRequestForm(head: head, title: defaultTitle, body: defaultBody, bases: bases)
        guard let response = await present(form.alert, purpose: "pull request form") else { return nil }
        guard response == .alertFirstButtonReturn else { return nil }
        return form.draft
    }

    /// The form's alert and its controls, Create first and enabled only while the title
    /// holds something other than whitespace.
    static func pullRequestForm(head: String, title: String, body: String, bases: [String]) -> PullRequestForm {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Create Pull Request for \(head)"
        alert.informativeText = ""
        let create = alert.addButton(withTitle: "Create")
        create.setAccessibilityIdentifier("git.prompt.action")
        alert.addButton(withTitle: "Cancel").setAccessibilityIdentifier("git.prompt.cancel")
        alert.window.setAccessibilityIdentifier("git.pullRequest.form")

        let titleField = NSTextField(string: title)
        titleField.setAccessibilityLabel("Title")
        titleField.setAccessibilityIdentifier("git.pullRequest.form.title")
        titleField.widthAnchor.constraint(greaterThanOrEqualToConstant: 360).isActive = true

        let bodyView = NSTextView()
        bodyView.string = body
        bodyView.isRichText = false
        bodyView.font = .systemFont(ofSize: NSFont.systemFontSize)
        bodyView.isVerticallyResizable = true
        bodyView.autoresizingMask = [.width]
        bodyView.textContainer?.widthTracksTextView = true
        bodyView.setAccessibilityLabel("Body")
        bodyView.setAccessibilityIdentifier("git.pullRequest.form.body")
        let bodyScroll = NSScrollView()
        bodyScroll.documentView = bodyView
        bodyScroll.hasVerticalScroller = true
        bodyScroll.borderType = .bezelBorder
        bodyScroll.setAccessibilityIdentifier("git.pullRequest.form.bodyScroll")
        bodyScroll.widthAnchor.constraint(greaterThanOrEqualToConstant: 360).isActive = true
        bodyScroll.heightAnchor.constraint(equalToConstant: 140).isActive = true

        let basePopUp = NSPopUpButton(frame: .zero, pullsDown: false)
        basePopUp.addItems(withTitles: bases)
        basePopUp.isEnabled = !bases.isEmpty
        basePopUp.setAccessibilityLabel("Base")
        basePopUp.setAccessibilityIdentifier("git.pullRequest.form.base")

        let draftBox = NSButton(checkboxWithTitle: "Draft", target: nil, action: nil)
        draftBox.setAccessibilityIdentifier("git.pullRequest.form.draft")

        let captions = ["Title", "Body", "Base"].map { title in
            let caption = NSTextField(labelWithString: title)
            caption.setAccessibilityIdentifier("git.pullRequest.form.caption.\(title.lowercased())")
            return caption
        }
        let grid = NSGridView(views: [
            [captions[0], titleField],
            [captions[1], bodyScroll],
            [captions[2], basePopUp],
            [NSGridCell.emptyContentView, draftBox]
        ])
        grid.setAccessibilityIdentifier("git.pullRequest.form.fields")
        grid.column(at: 0).xPlacement = .trailing
        grid.rowAlignment = .firstBaseline
        grid.columnSpacing = 8
        grid.rowSpacing = 8
        grid.frame = NSRect(x: 0, y: 0, width: 440, height: grid.fittingSize.height)
        alert.accessoryView = grid

        let enabler = TitleEnabler(field: titleField, action: create)
        enabler.update()
        alert.layout()
        alert.window.initialFirstResponder = titleField
        return PullRequestForm(alert: alert, titleField: titleField, bodyView: bodyView, basePopUp: basePopUp,
                               draftBox: draftBox, enabler: enabler)
    }

    /// A built pull request form: the alert and the controls its answer is read from.
    struct PullRequestForm {
        let alert: NSAlert
        let titleField: NSTextField
        let bodyView: NSTextView
        let basePopUp: NSPopUpButton
        let draftBox: NSButton
        /// Held with the form: the title field's delegate is weak.
        let enabler: NSObject

        /// The values as the user left them, title and body trimmed.
        var draft: GitPullRequestDraft {
            GitPullRequestDraft(
                title: titleField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
                body: bodyView.string.trimmingCharacters(in: .whitespacesAndNewlines),
                base: basePopUp.isEnabled ? basePopUp.titleOfSelectedItem : nil,
                draft: draftBox.state == .on)
        }
    }
}

/// Keeps the form's Create button enabled only while the title is not blank.
private final class TitleEnabler: NSObject, NSTextFieldDelegate {
    private let field: NSTextField
    private weak var action: NSButton?

    init(field: NSTextField, action: NSButton) {
        self.field = field
        self.action = action
        super.init()
        field.delegate = self
    }

    func update() {
        action?.isEnabled = !field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func controlTextDidChange(_ obj: Notification) {
        update()
    }
}
