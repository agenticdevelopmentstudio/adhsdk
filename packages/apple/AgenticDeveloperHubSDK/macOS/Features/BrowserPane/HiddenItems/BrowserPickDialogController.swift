//
//  BrowserPickDialogController.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCoreMacOS
import AppKit
import AgenticDeveloperHubSDKDatabase

/// The dialog a pick opens (recipe `workspace/browser/element-picker`):
///
/// ```
/// ( This item | All items like it )
/// [ ] Show page with selected element removed
/// Remove this from view?                 [Cancel] [OK]
/// ```
///
/// A window of its own, run app-modal through the shared
/// `AppModalWindowSession` rather than as a sheet, so it can be dragged off
/// the item it is about. The preview goes through
/// `preview`, which the selecting mode points at the engine's preview rule
/// set; WebKit keeps running in the modal panel run-loop mode, so the page
/// redraws while the dialog is up. Every way out clears the preview.
@MainActor
final class BrowserPickDialogController: NSObject, NSWindowDelegate {

    /// What OK saves: the chosen scope's selector, and that scope.
    struct Choice: Equatable {
        let selector: String
        let scope: BrowserHiddenItemScope
    }

    static let thisItemTitle = "This item"
    static let allLikeItTitle = "All items like it"
    static let tooMuchToolTip = "Matches too much of the page"
    static let noLooserToolTip = "No looser selector is available"
    static let previewTitle = "Show page with selected element removed"

    let candidate: BrowserPickCandidate
    let list: BrowserHiddenItemList
    let window: NSWindow
    let scopeControl = NSSegmentedControl(
        labels: [BrowserPickDialogController.thisItemTitle, BrowserPickDialogController.allLikeItTitle],
        trackingMode: .selectOne, target: nil, action: nil)
    let previewCheckbox = NSButton(
        checkboxWithTitle: BrowserPickDialogController.previewTitle, target: nil, action: nil)
    let questionLabel: NSTextField
    let cancelButton = NSButton(title: "Cancel", target: nil, action: nil)
    let okButton = NSButton(title: "OK", target: nil, action: nil)

    /// Called with the selectors to preview, or nil to clear the preview.
    private let preview: ([String]?) -> Void
    /// Called once, with the choice on OK and nil on Cancel. Not called when
    /// the dialog is dismissed from outside (`dismiss()`).
    private var onClose: ((Choice?) -> Void)?
    private var isFinished = false
    /// The app-modal session, from `present(over:)` until the dialog ends.
    private var modalSession: AppModalWindowSession?

    init(candidate: BrowserPickCandidate, list: BrowserHiddenItemList,
         preview: @escaping ([String]?) -> Void,
         onClose: @escaping (Choice?) -> Void) {
        self.candidate = candidate
        self.list = list
        self.preview = preview
        self.onClose = onClose
        questionLabel = NSTextField(labelWithString: Self.question(for: list))
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 140),
            styleMask: [.titled, .closable], backing: .buffered, defer: true)
        super.init()
        window.title = Self.title(for: list)
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.delegate = self
        buildContent()
    }

    static func question(for list: BrowserHiddenItemList) -> String {
        list == .agent ? "Hide this from the agent?" : "Remove this from view?"
    }

    static func title(for list: BrowserHiddenItemList) -> String {
        list == .agent ? "Hide from the Agent" : "Hide Distracting Item"
    }

    private func buildContent() {
        scopeControl.target = self
        scopeControl.action = #selector(scopeChanged(_:))
        scopeControl.selectedSegment = 0
        if !candidate.allLikeItAllowed {
            scopeControl.setEnabled(false, forSegment: 1)
            scopeControl.setToolTip(
                candidate.allLikeIt == nil ? Self.noLooserToolTip : Self.tooMuchToolTip, forSegment: 1)
        }
        scopeControl.setAccessibilityIdentifier("browser.pick.scope")

        previewCheckbox.target = self
        previewCheckbox.action = #selector(previewToggled(_:))
        previewCheckbox.state = .off
        previewCheckbox.setAccessibilityIdentifier("browser.pick.preview")

        cancelButton.target = self
        cancelButton.action = #selector(cancel(_:))
        cancelButton.keyEquivalent = "\u{1b}"
        cancelButton.setAccessibilityIdentifier("browser.pick.cancel")
        okButton.target = self
        okButton.action = #selector(confirm(_:))
        okButton.keyEquivalent = "\r"
        okButton.setAccessibilityIdentifier("browser.pick.ok")

        let spacer = NSView()
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)
        let bottom = NSStackView(views: [questionLabel, spacer, cancelButton, okButton])
        bottom.orientation = .horizontal
        bottom.alignment = .centerY
        bottom.spacing = 8

        let stack = NSStackView(views: [scopeControl, previewCheckbox, bottom])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            stack.topAnchor.constraint(equalTo: content.topAnchor),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            bottom.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40),
            content.widthAnchor.constraint(greaterThanOrEqualToConstant: 380)
        ])
        window.contentView = content
        window.defaultButtonCell = okButton.cell as? NSButtonCell
        window.initialFirstResponder = okButton
    }

    // MARK: - State

    /// The scope the segmented control shows: This item unless All items
    /// like it is chosen and allowed.
    var chosenScope: BrowserHiddenItemScope {
        scopeControl.selectedSegment == 1 && candidate.allLikeItAllowed ? .allLikeIt : .thisItem
    }

    /// The chosen scope's selector; nil only for a candidate with no This
    /// item selector, which the picker never delivers.
    var chosenSelector: String? {
        chosenScope == .allLikeIt ? candidate.allLikeIt : candidate.thisItem
    }

    private func applyPreview() {
        guard !isFinished else { return }
        if previewCheckbox.state == .on, let selector = chosenSelector {
            preview([selector])
        } else {
            preview(nil)
        }
    }

    // MARK: - Actions

    @objc func scopeChanged(_ sender: Any?) {
        if !candidate.allLikeItAllowed { scopeControl.selectedSegment = 0 }
        applyPreview()
    }

    @objc func previewToggled(_ sender: Any?) {
        applyPreview()
    }

    @objc func confirm(_ sender: Any?) {
        guard let selector = chosenSelector else {
            finish(nil)
            return
        }
        finish(Choice(selector: selector, scope: chosenScope))
    }

    @objc func cancel(_ sender: Any?) {
        finish(nil)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        finish(nil)
        return false
    }

    // MARK: - Running

    /// Centres the dialog over `parent` (else the screen) and runs it
    /// app-modal until OK, Cancel or `dismiss()`. The session starts on the
    /// run loop's next pass, so this returns at once. Does nothing if the
    /// dialog was dismissed before it could run.
    func present(over parent: NSWindow?) {
        guard !isFinished, modalSession == nil else { return }
        applyPreview()
        if let parent {
            let frame = parent.frame
            let size = window.frame.size
            window.setFrameOrigin(NSPoint(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2))
        } else {
            window.center()
        }
        let session = AppModalWindowSession(window: window)
        modalSession = session
        session.start()
    }

    /// Ends the dialog with `choice` (nil for Cancel), clearing the preview.
    func finish(_ choice: Choice?) {
        guard !isFinished else { return }
        isFinished = true
        preview(nil)
        endSession()
        deliver(choice)
    }

    /// Closes the dialog without saving and without calling `onClose`: the
    /// selecting mode ended under it (navigation, tab switch, close). The
    /// shared session stops without an event, so a WebKit callback can call
    /// this.
    func dismiss() {
        guard !isFinished else { return }
        isFinished = true
        onClose = nil
        preview(nil)
        endSession()
    }

    private func endSession() {
        modalSession?.end()
        modalSession = nil
        window.orderOut(nil)
    }

    private func deliver(_ choice: Choice?) {
        let handler = onClose
        onClose = nil
        handler?(choice)
    }
}
