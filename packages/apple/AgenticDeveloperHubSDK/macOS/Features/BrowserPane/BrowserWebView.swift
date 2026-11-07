//
//  BrowserWebView.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import WebKit

/// The browser pane's web view: `LiveResizingWebView` that hands the page an
/// event only when its `BrowserInputGate` allows it.
///
/// Each override calls `super` only when allowed. The gate covers the web view
/// alone, so the pane's address bar and chrome keep working however the page is
/// gated. `performKeyEquivalent` answers `false` when blocked, which sends the
/// shortcut on to the menu bar instead of swallowing it.
public final class BrowserWebView: LiveResizingWebView {
    /// What the pane lets through. Open until the pane sets one.
    public var gate: BrowserInputGate = .open

    /// Told every decision: channel, event name, whether it was delivered,
    /// whether it was the agent's. The event log (section 8) reads this.
    public var onInputDecision: ((BrowserInputChannel, String, Bool, Bool) -> Void)?

    private var automationDepth = 0

    /// Runs `body` with every event it delivers marked as the agent's.
    public func deliveringAutomationInput<T>(_ body: () throws -> T) rethrows -> T {
        automationDepth += 1
        defer { automationDepth -= 1 }
        return try body()
    }

    /// The window is key and the first responder is this view or inside it.
    var pageHasFocus: Bool {
        guard let window, window.isKeyWindow else { return false }
        return holdsFirstResponder
    }

    private func allows(_ channel: BrowserInputChannel, _ event: String) -> Bool {
        let synthesized = automationDepth > 0
        let delivered = gate.allows(channel, synthesized: synthesized, pageHasFocus: pageHasFocus)
        onInputDecision?(channel, event, delivered, synthesized)
        return delivered
    }

    // MARK: - Keyboard

    /// The first responder is this view or inside it, whether or not the
    /// window is key.
    private var holdsFirstResponder: Bool {
        guard let responder = window?.firstResponder as? NSView else { return false }
        return responder === self || responder.isDescendant(of: self)
    }

    /// True while WebKit handles a keyDown the gate already let through, so
    /// the text it inserts for that key is not decided (and reported) twice.
    private var isHandlingAllowedKeyDown = false

    public override func keyDown(with event: NSEvent) {
        guard allows(.keyboard, "keyDown") else { return }
        isHandlingAllowedKeyDown = true
        defer { isHandlingAllowedKeyDown = false }
        super.keyDown(with: event)
    }

    public override func keyUp(with event: NSEvent) {
        if allows(.keyboard, "keyUp") { super.keyUp(with: event) }
    }

    public override func flagsChanged(with event: NSEvent) {
        if allows(.keyboard, "flagsChanged") { super.flagsChanged(with: event) }
    }

    /// NSWindow offers every key equivalent to every view in the window, so a
    /// Cmd-shortcut typed in the address bar arrives here too. Only one meant
    /// for the page (the page holds first responder) is gated and reported;
    /// the rest go to WebKit untouched, as they would without this subclass.
    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard holdsFirstResponder else { return super.performKeyEquivalent(with: event) }
        return allows(.keyboard, "performKeyEquivalent") ? super.performKeyEquivalent(with: event) : false
    }

    // MARK: - Mouse (back and forward swipes follow it)

    public override func mouseDown(with event: NSEvent) {
        if allows(.mouse, "mouseDown") { super.mouseDown(with: event) }
    }

    public override func mouseUp(with event: NSEvent) {
        if allows(.mouse, "mouseUp") { super.mouseUp(with: event) }
    }

    public override func mouseDragged(with event: NSEvent) {
        if allows(.mouse, "mouseDragged") { super.mouseDragged(with: event) }
    }

    public override func rightMouseDown(with event: NSEvent) {
        if allows(.mouse, "rightMouseDown") { super.rightMouseDown(with: event) }
    }

    public override func rightMouseUp(with event: NSEvent) {
        if allows(.mouse, "rightMouseUp") { super.rightMouseUp(with: event) }
    }

    public override func rightMouseDragged(with event: NSEvent) {
        if allows(.mouse, "rightMouseDragged") { super.rightMouseDragged(with: event) }
    }

    public override func otherMouseDown(with event: NSEvent) {
        if allows(.mouse, "otherMouseDown") { super.otherMouseDown(with: event) }
    }

    public override func otherMouseUp(with event: NSEvent) {
        if allows(.mouse, "otherMouseUp") { super.otherMouseUp(with: event) }
    }

    public override func otherMouseDragged(with event: NSEvent) {
        if allows(.mouse, "otherMouseDragged") { super.otherMouseDragged(with: event) }
    }

    public override func scrollWheel(with event: NSEvent) {
        if allows(.mouse, "scrollWheel") { super.scrollWheel(with: event) }
    }

    public override func magnify(with event: NSEvent) {
        if allows(.mouse, "magnify") { super.magnify(with: event) }
    }

    public override func rotate(with event: NSEvent) {
        if allows(.mouse, "rotate") { super.rotate(with: event) }
    }

    public override func swipe(with event: NSEvent) {
        if allows(.mouse, "swipe") { super.swipe(with: event) }
    }

    public override func smartMagnify(with event: NSEvent) {
        if allows(.mouse, "smartMagnify") { super.smartMagnify(with: event) }
    }

    public override func pressureChange(with event: NSEvent) {
        if allows(.mouse, "pressureChange") { super.pressureChange(with: event) }
    }

    // MARK: - Pointer tracking

    public override func mouseMoved(with event: NSEvent) {
        if allows(.pointer, "mouseMoved") { super.mouseMoved(with: event) }
    }

    public override func mouseEntered(with event: NSEvent) {
        if allows(.pointer, "mouseEntered") { super.mouseEntered(with: event) }
    }

    public override func mouseExited(with event: NSEvent) {
        if allows(.pointer, "mouseExited") { super.mouseExited(with: event) }
    }

    public override func cursorUpdate(with event: NSEvent) {
        if allows(.pointer, "cursorUpdate") { super.cursorUpdate(with: event) }
    }

    // MARK: - Drag and drop

    public override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        allows(.dragAndDrop, "draggingEntered") ? super.draggingEntered(sender) : []
    }

    public override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        allows(.dragAndDrop, "draggingUpdated") ? super.draggingUpdated(sender) : []
    }

    /// Not in section 5's table: AppKit already skips the drop when the last
    /// `draggingUpdated` answered none, so this is the second lock on the
    /// same door, for a gate that closes between that answer and the drop.
    public override func prepareForDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        allows(.dragAndDrop, "prepareForDragOperation") ? super.prepareForDragOperation(sender) : false
    }

    public override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        allows(.dragAndDrop, "performDragOperation") ? super.performDragOperation(sender) : false
    }

    // MARK: - Edit actions (keyboard)

    /// Edit-menu actions that carry keyboard intent or clipboard content.
    /// A blocked `performKeyEquivalent` sends Cmd-V on to the menu bar, and the
    /// menu item would then send `paste:` straight back down the responder
    /// chain to this view, so the keyboard gate has to hold these too. Delete
    /// and the Transformations items edit the page's text the same way.
    nonisolated static let gatedEditActions: Set<Selector> = [
        #selector(NSText.paste(_:)),
        #selector(NSTextView.pasteAsPlainText(_:)),
        #selector(NSTextView.pasteAsRichText(_:)),
        #selector(NSText.cut(_:)),
        #selector(NSText.copy(_:)),
        #selector(NSText.selectAll(_:)),
        Selector(("undo:")),
        Selector(("redo:")),
        #selector(NSText.delete(_:)),
        #selector(NSResponder.uppercaseWord(_:)),
        #selector(NSResponder.lowercaseWord(_:)),
        #selector(NSResponder.capitalizeWord(_:))
    ]

    /// Whether the keyboard gate would let the user's input through right now,
    /// without reporting a decision. Menu validation asks this on every menu
    /// open, which is not an event worth logging.
    private var keyboardAllowedQuietly: Bool {
        gate.allows(.keyboard, synthesized: automationDepth > 0, pageHasFocus: pageHasFocus)
    }

    /// The gated actions WebKit itself does not implement (`undo:`, `redo:`,
    /// `pasteAsRichText:` are answered further up the chain, by the window).
    /// While the keyboard is allowed this view says it does not respond to
    /// them, so the responder chain finds their real handler and validates
    /// exactly as it would without this subclass. `responds(to:)` is
    /// nonisolated and may be asked off the main thread; there the gate cannot
    /// be read, and the answer is WebKit's own (menu validation is main-thread).
    public override nonisolated func responds(to aSelector: Selector!) -> Bool {
        if let aSelector, Thread.isMainThread, Self.gatedEditActions.contains(aSelector),
           !Self.superResponds(to: aSelector) {
            return MainActor.assumeIsolated { !keyboardAllowedQuietly }
        }
        return super.responds(to: aSelector)
    }

    /// Disables the gated Edit items while the keyboard is blocked.
    public override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        if let action = item.action, Self.gatedEditActions.contains(action) {
            guard keyboardAllowedQuietly else { return false }
            if !Self.superResponds(to: action) { return true }
        }
        return super.validateUserInterfaceItem(item)
    }

    @objc(paste:) public func gatedPaste(_ sender: Any?) { performEditAction("paste:", sender) }
    @objc(pasteAsPlainText:) public func gatedPasteAsPlainText(_ sender: Any?) {
        performEditAction("pasteAsPlainText:", sender)
    }
    @objc(pasteAsRichText:) public func gatedPasteAsRichText(_ sender: Any?) {
        performEditAction("pasteAsRichText:", sender)
    }
    @objc(cut:) public func gatedCut(_ sender: Any?) { performEditAction("cut:", sender) }
    @objc(copy:) public func gatedCopy(_ sender: Any?) { performEditAction("copy:", sender) }
    @objc(selectAll:) public func gatedSelectAll(_ sender: Any?) { performEditAction("selectAll:", sender) }
    @objc(undo:) public func gatedUndo(_ sender: Any?) { performEditAction("undo:", sender) }
    @objc(redo:) public func gatedRedo(_ sender: Any?) { performEditAction("redo:", sender) }
    @objc(delete:) public func gatedDelete(_ sender: Any?) { performEditAction("delete:", sender) }
    @objc(uppercaseWord:) public func gatedUppercaseWord(_ sender: Any?) {
        performEditAction("uppercaseWord:", sender)
    }
    @objc(lowercaseWord:) public func gatedLowercaseWord(_ sender: Any?) {
        performEditAction("lowercaseWord:", sender)
    }
    @objc(capitalizeWord:) public func gatedCapitalizeWord(_ sender: Any?) {
        performEditAction("capitalizeWord:", sender)
    }

    // MARK: - Text input with no keyDown (keyboard)

    // WKWebView is itself the window's NSTextInputClient (it conforms and
    // implements these; its one subview, WKFlippedView, never takes first
    // responder), so Dictation and Emoji & Symbols, which insert text without
    // a keyDown, come through here. Text for a keyDown the gate already let
    // through passes without a second decision.

    @objc(insertText:) public func gatedInsertText(_ string: Any) {
        guard allowsTextInput("insertText:") else { return }
        let selector = #selector(gatedInsertText(_:))
        guard let imp = class_getMethodImplementation(LiveResizingWebView.self, selector) else { return }
        unsafeBitCast(imp, to: ActionIMP.self)(self, selector, string as AnyObject)
    }

    @objc(insertText:replacementRange:) public func gatedInsertText(_ string: Any, replacementRange: NSRange) {
        guard allowsTextInput("insertText:replacementRange:") else { return }
        typealias IMP = @convention(c) (AnyObject, Selector, AnyObject, NSRange) -> Void
        let selector = #selector(gatedInsertText(_:replacementRange:))
        guard let imp = class_getMethodImplementation(LiveResizingWebView.self, selector) else { return }
        unsafeBitCast(imp, to: IMP.self)(self, selector, string as AnyObject, replacementRange)
    }

    /// Dictation shows its interim words as marked text before it commits
    /// them with `insertText`; withholding only the commit would leave them
    /// stranded in the page.
    @objc(setMarkedText:selectedRange:replacementRange:)
    public func gatedSetMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        guard allowsTextInput("setMarkedText:selectedRange:replacementRange:") else { return }
        typealias IMP = @convention(c) (AnyObject, Selector, AnyObject, NSRange, NSRange) -> Void
        let selector = #selector(gatedSetMarkedText(_:selectedRange:replacementRange:))
        guard let imp = class_getMethodImplementation(LiveResizingWebView.self, selector) else { return }
        unsafeBitCast(imp, to: IMP.self)(self, selector, string as AnyObject, selectedRange, replacementRange)
    }

    private func allowsTextInput(_ name: String) -> Bool {
        isHandlingAllowedKeyDown || allows(.keyboard, name)
    }

    private typealias ActionIMP = @convention(c) (AnyObject, Selector, AnyObject?) -> Void

    private nonisolated static func superResponds(to selector: Selector) -> Bool {
        LiveResizingWebView.instancesRespond(to: selector)
    }

    /// Drops the action when the keyboard is blocked; otherwise hands it to
    /// WebKit's own implementation, or, for an action WebKit does not
    /// implement (reached by a direct call), on up the responder chain.
    private func performEditAction(_ name: String, _ sender: Any?) {
        let selector = Selector(name)
        guard allows(.keyboard, name) else { return }
        if Self.superResponds(to: selector),
           let imp = class_getMethodImplementation(LiveResizingWebView.self, selector) {
            unsafeBitCast(imp, to: ActionIMP.self)(self, selector, sender as AnyObject?)
        } else if nextResponder?.tryToPerform(selector, with: sender) != true {
            NSApp.tryToPerform(selector, with: sender)
        }
    }
}
