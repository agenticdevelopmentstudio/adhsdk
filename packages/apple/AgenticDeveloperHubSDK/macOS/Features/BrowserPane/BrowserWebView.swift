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
        guard let window, window.isKeyWindow, let responder = window.firstResponder as? NSView else { return false }
        return responder === self || responder.isDescendant(of: self)
    }

    private func allows(_ channel: BrowserInputChannel, _ event: String) -> Bool {
        let synthesized = automationDepth > 0
        let delivered = gate.allows(channel, synthesized: synthesized, pageHasFocus: pageHasFocus)
        onInputDecision?(channel, event, delivered, synthesized)
        return delivered
    }

    // MARK: - Keyboard

    public override func keyDown(with event: NSEvent) {
        if allows(.keyboard, "keyDown") { super.keyDown(with: event) }
    }

    public override func keyUp(with event: NSEvent) {
        if allows(.keyboard, "keyUp") { super.keyUp(with: event) }
    }

    public override func flagsChanged(with event: NSEvent) {
        if allows(.keyboard, "flagsChanged") { super.flagsChanged(with: event) }
    }

    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        allows(.keyboard, "performKeyEquivalent") ? super.performKeyEquivalent(with: event) : false
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
}
