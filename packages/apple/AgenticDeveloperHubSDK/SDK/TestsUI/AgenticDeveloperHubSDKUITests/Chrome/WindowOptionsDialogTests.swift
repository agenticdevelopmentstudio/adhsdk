import Testing
import AppKit
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// The gear a window puts at the trailing edge of its title bar, the dialog it
/// raises, and the two controls that hang inside it.
///
/// Nothing here calls `present()`. It enters an app-modal run loop that only a
/// `Done` press or a close button ends, so a test that called it would never
/// return — which is exactly why `present()` is `beginDialog()`, the modal
/// loop, and `endDialog(_:)`. Everything that happens while the dialog is up is
/// covered through that seam.
@MainActor
@Suite("WindowOptionsDialog")
struct WindowOptionsDialogTests {

    private func slider(in view: NSView) -> NSSlider? {
        if let slider = view as? NSSlider { return slider }
        for subview in view.subviews {
            if let found = slider(in: subview) { return found }
        }
        return nil
    }

    private func button(in view: NSView) -> NSButton? {
        if let button = view as? NSButton { return button }
        for subview in view.subviews {
            if let found = button(in: subview) { return found }
        }
        return nil
    }

    private func labels(in view: NSView) -> [String] {
        var found: [String] = []
        if let field = view as? NSTextField { found.append(field.stringValue) }
        for subview in view.subviews { found += labels(in: subview) }
        return found
    }

    // MARK: The gear

    @Test("the gear carries an icon and its own action, and starts closed")
    func gearIsWired() {
        var built = false
        let options = WindowOptionsDialog(title: "Olylo Window") {
            built = true
            return []
        }
        #expect(options.gearButton.image != nil)
        #expect(options.gearButton.target != nil)
        #expect(options.gearButton.action != nil)
        #expect(options.isShown == false)
        // The controls are a host's closure over live state, so they are built
        // when the dialog opens rather than at construction.
        #expect(built == false)
    }

    /// `NSTitlebarAccessoryViewController` lays its view out by frame, not by
    /// auto layout: a purely constraint-driven container reports zero width and
    /// never appears, which is a bug you can only see by looking at the window.
    @Test("the titlebar accessory has a real frame and holds the gear")
    func accessoryHasAFrame() {
        let options = WindowOptionsDialog(title: "Olylo Window") { [] }
        let controller = options.makeTitlebarAccessory()
        #expect(controller.view.frame.width > 0)
        #expect(controller.view.frame.height > 0)
        #expect(controller.layoutAttribute == .right)

        var contains = false
        func walk(_ view: NSView) {
            if view === options.gearButton { contains = true }
            view.subviews.forEach(walk)
        }
        walk(controller.view)
        #expect(contains)
    }

    @Test("leading chrome sits alongside the gear rather than replacing it")
    func accessoryKeepsLeadingViews() {
        let options = WindowOptionsDialog(title: "Olylo Window") { [] }
        let extra = NSButton(title: "x", target: nil, action: nil)
        let controller = options.makeTitlebarAccessory(leading: [extra], width: 160)
        var seen: [NSView] = []
        func walk(_ view: NSView) {
            seen.append(view)
            view.subviews.forEach(walk)
        }
        walk(controller.view)
        #expect(seen.contains { $0 === extra })
        #expect(seen.contains { $0 === options.gearButton })
        #expect(controller.view.frame.width == 160)
    }

    /// `install(leading:)` is the documented way for a host to put its own
    /// chrome next to the gear and it passes no width, so the *default* is the
    /// number every one of those hosts actually gets. Halving it cramps them
    /// all, and no test that passes a width explicitly would notice.
    @Test("the default accessory is wide enough for leading chrome beside the gear")
    func accessoryDefaultWidthLeavesRoom() {
        let options = WindowOptionsDialog(title: "Olylo Window") { [] }
        let controller = options.makeTitlebarAccessory(leading: [
            NSButton(title: "Connect", target: nil, action: nil)
        ])
        #expect(controller.view.frame.width == 240)
    }

    // MARK: The dialog window

    /// A popover rode the window it was configuring, which is why the window
    /// had to be frozen while it was up. A dialog is its own window, so the
    /// window behind it is free to resize under every change — and a dialog
    /// that came back as a sheet or a child window would take that away again.
    @Test("the dialog is a titled, closable window of its own, carrying the title")
    func dialogIsItsOwnWindow() {
        let options = WindowOptionsDialog(title: "Olylo Window") { [NSSlider()] }
        let window = options.makeDialogWindow()
        #expect(window.title == "Olylo Window")
        #expect(window.styleMask.contains(.titled))
        #expect(window.styleMask.contains(.closable))
        #expect(window.parent == nil)
        #expect(window.delegate === options)
    }

    /// A host at an unusual level has a reason for being there, and the dialog
    /// has to follow it: a HUD the user has floated above other apps would
    /// otherwise raise its own options *behind* itself, and a window sunk below
    /// the desktop picture (a test, or an automated session driving the app
    /// while its user works elsewhere) would have this dialog be the one window
    /// that surfaced in front of them.
    @Test("the dialog opens at the level of the window it configures")
    func dialogMatchesItsHostsLevel() {
        for level in [NSWindow.Level.floating,
                      NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)))] {
            let options = WindowOptionsDialog(title: "Olylo Window") { [] }
            let host = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
                styleMask: [.titled], backing: .buffered, defer: true)
            host.level = level
            host.contentView?.addSubview(options.gearButton)

            #expect(options.makeDialogWindow().level == level)
        }
    }

    @Test("a gear that is not in a window yet raises an ordinary dialog")
    func dialogWithoutAHostIsNormalLevel() {
        let options = WindowOptionsDialog(title: "Olylo Window") { [] }
        #expect(options.makeDialogWindow().level == .normal)
    }

    /// The window's title bar already says the name. A heading inside saying it
    /// again is the popover's layout surviving into a container that does not
    /// need it.
    @Test("the dialog's body does not repeat the title as a heading")
    func dialogBodyHasNoHeading() throws {
        let options = WindowOptionsDialog(title: "Olylo Window") { [] }
        let window = options.makeDialogWindow()
        let body = try #require(window.contentViewController)
        body.view.layoutSubtreeIfNeeded()
        #expect(!labels(in: body.view).contains("Olylo Window"))
    }

    /// `close()` is what ends the modal session, so every way out has to go
    /// through it — and it has to be safe when there is nothing to close, since
    /// `Done`, the close button and ⌘W can all arrive for the same dialog.
    @Test("closing a dialog that is not up does nothing")
    func closingAClosedDialogIsFree() {
        let options = WindowOptionsDialog(title: "Olylo Window") { [] }
        options.close()
        #expect(options.isShown == false)
    }

    /// The close button must not be allowed to close the window itself: the
    /// modal loop would keep running with nothing on screen.
    @Test("the close button is refused and routed through close()")
    func closeButtonRoutesThroughClose() {
        let options = WindowOptionsDialog(title: "Olylo Window") { [] }
        let window = options.makeDialogWindow()
        #expect(options.windowShouldClose(window) == false)
    }

    // MARK: Opening and closing

    /// A dialog whose gear is really in a window, which is what makes
    /// `hostLevel` and the screen the dialog centres on mean anything.
    private func hostedDialog(
        makeControls: @escaping @MainActor () -> [NSView] = { [] }
    ) -> (WindowOptionsDialog, NSWindow) {
        let options = WindowOptionsDialog(title: "Olylo Window", makeControls: makeControls)
        let host = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled], backing: .buffered, defer: true)
        host.contentView?.addSubview(options.gearButton)
        return (options, host)
    }

    /// The gear is still clickable while its dialog is up — it is in the host's
    /// title bar, and the host is only app-modal-blocked, not gone. A second
    /// open would strand the first window on screen with nothing holding it.
    @Test("a second open while one is up is refused and leaves the first alone")
    func openingTwiceKeepsOneDialog() throws {
        var builds = 0
        let (options, _) = hostedDialog { builds += 1; return [] }
        let first = try #require(options.beginDialog())
        #expect(options.isShown)
        #expect(builds == 1)

        #expect(options.beginDialog() == nil)
        #expect(builds == 1)

        options.endDialog(first)
        #expect(options.isShown == false)
    }

    @Test("closing an open dialog takes it off screen and forgets it")
    func closingAnOpenDialogTakesItDown() throws {
        let (options, _) = hostedDialog()
        let window = try #require(options.beginDialog())

        options.close()
        #expect(options.isShown == false)
        #expect(window.isVisible == false)

        // `Done`, the close button and ⌘W can all arrive for one dialog.
        options.close()
        #expect(options.isShown == false)
    }

    /// Centred on the *screen*, not on the host and not on the gear: a window
    /// dragged into the corner of a large display would otherwise raise its
    /// options down in the corner with it.
    @Test("the dialog opens centred on the screen its host is on")
    func dialogOpensCentredOnTheHostsScreen() throws {
        let (options, host) = hostedDialog {
            [WindowOptionsToggle(title: "Float", isOn: false) { _ in }]
        }
        host.setFrameOrigin(.zero)
        let visible = try #require(host.screen ?? NSScreen.main).visibleFrame

        let window = try #require(options.beginDialog())
        #expect(abs(window.frame.midX - visible.midX) < 1)
        #expect(abs(window.frame.midY - visible.midY) < 1)
        options.endDialog(window)
    }

    /// "Always on top" is one of the controls *inside* this dialog. Sampling the
    /// host's level once at open meant flipping it raised the host above an
    /// app-modal dialog still sitting at `.normal`: the app takes no input and
    /// the only window that would give it back is behind the one in front.
    @Test("raising the host while the dialog is up raises the dialog with it")
    func dialogFollowsTheHostsLevelWhileOpen() throws {
        let (options, host) = hostedDialog()
        let window = try #require(options.beginDialog())
        #expect(window.level == .normal)

        host.level = .floating
        NotificationCenter.default.post(name: NSWindow.didUpdateNotification, object: window)
        #expect(window.level == .floating)

        // And back down again, so the dialog does not outrank a host that has
        // stopped floating.
        host.level = .normal
        NotificationCenter.default.post(name: NSWindow.didUpdateNotification, object: window)
        #expect(window.level == .normal)

        options.endDialog(window)
        host.level = .floating
        NotificationCenter.default.post(name: NSWindow.didUpdateNotification, object: window)
        #expect(window.level == .normal)  // a closed dialog follows nothing
    }

    /// A rebuild is what an open dialog does when something else moved one of
    /// its values. Re-reading them can change how tall the body is — a row that
    /// appears, a caption that wraps — and a window left at its old size would
    /// clip the new body or leave a gap under it.
    @Test("rebuilding an open dialog resizes it to the new body")
    func rebuildOfAnOpenDialogResizesIt() throws {
        var rows: [NSView] = [WindowOptionsToggle(title: "Float", isOn: false) { _ in }]
        let (options, _) = hostedDialog { rows }
        let window = try #require(options.beginDialog())
        let firstHeight = window.frame.height

        rows = (0..<6).map { index in
            WindowOptionsToggle(title: "Row \(index)", isOn: false) { _ in }
        }
        options.rebuildControls()

        #expect(window.frame.height > firstHeight)
        options.endDialog(window)
    }

    // MARK: The body

    @Test("the body captions itself and lays every control out at one width")
    func bodyHoldsItsControls() {
        let first = WindowOptionsToggle(title: "Float", isOn: false) { _ in }
        let second = WindowOptionsToggle(title: "Blink caret", isOn: true) { _ in }
        let controller = OptionsDialogViewController(
            heading: "Olylo Window", rows: [first, second])
        controller.view.frame = NSRect(origin: .zero, size: controller.view.fittingSize)
        controller.view.layoutSubtreeIfNeeded()

        #expect(labels(in: controller.view).contains("Olylo Window"))
        #expect(controller.view.fittingSize.width == OptionsDialogViewController.defaultWidth)
        // A slider that sized to its own content would start and end somewhere
        // different in each row; every control spans the same width instead.
        #expect(first.frame.width == second.frame.width)
        #expect(first.frame.width > 0)
    }

    /// `width` is documented as what a dialog is wide *unless its rows need
    /// more*. Pinned to an exact constant that second half was not true: the
    /// constraint is required, it outranks every row's compression resistance,
    /// and a row carrying something wider — a popup with a long provider name, a
    /// label and a trailing button — was squeezed and truncated instead.
    @Test("a row wider than the default widens the dialog instead of being squeezed")
    func aWideRowWidensTheDialog() {
        let wide = NSView()
        wide.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wide.widthAnchor.constraint(greaterThanOrEqualToConstant: 600),
            wide.heightAnchor.constraint(equalToConstant: 20)
        ])

        let controller = OptionsDialogViewController(heading: nil, rows: [wide])
        controller.view.layoutSubtreeIfNeeded()

        // 600 for the row, plus the insets it is held off both edges by.
        #expect(controller.view.fittingSize.width >= 640)
    }

    /// The only way out of the dialog, and the thing a modal presenter binds to
    /// stop its run loop. A `Done` that reported nothing would strand it.
    @Test("Done reports itself to whoever raised the dialog")
    func doneReportsItself() throws {
        var done = 0
        let controller = OptionsDialogViewController(heading: nil, rows: [])
        controller.onDone = { done += 1 }
        controller.view.layoutSubtreeIfNeeded()

        let button = try #require(self.button(in: controller.view))
        #expect(button.title == "Done")
        _ = button.target?.perform(button.action, with: button)
        #expect(done == 1)
    }

    /// A heading can be renamed while the dialog is up — a pane named by its
    /// content — and a heading frozen at construction would name the wrong one.
    @Test("renaming the heading changes what is on screen")
    func headingFollowsRenames() {
        let controller = OptionsDialogViewController(heading: "Olylo Window", rows: [])
        controller.view.layoutSubtreeIfNeeded()
        #expect(labels(in: controller.view).contains("Olylo Window"))

        controller.heading = "Files"

        #expect(labels(in: controller.view).contains("Files"))
        #expect(!labels(in: controller.view).contains("Olylo Window"))
    }

    // MARK: The controls

    @Test("a slider reports its title and a caption of where it is")
    func sliderCaptionsItself() {
        let control = WindowOptionsSlider(
            title: "Text Size", value: 1.25, range: 0.85...1.75,
            caption: { "\(Int(($0 * 100).rounded()))%" },
            onChange: { _ in })
        let text = labels(in: control)
        #expect(text.contains("Text Size"))
        // A slider between two unlabelled ends tells a reader only that they
        // have moved it; the caption is what lets them put it back.
        #expect(text.contains("125%"))
    }

    @Test("a slider clamps a stored value that has drifted outside its range")
    func sliderClampsItsStartingValue() {
        let control = WindowOptionsSlider(
            title: "Text Size", value: 9, range: 0.85...1.75,
            caption: { "\($0)" }, onChange: { _ in })
        #expect(control.value == 1.75)
    }

    @Test("moving a slider reports the new value as it goes")
    func sliderReportsChanges() throws {
        var reported: [Double] = []
        let control = WindowOptionsSlider(
            title: "Transparency", value: 1, range: 0.3...1.0,
            caption: { "\($0)" }, onChange: { reported.append($0) })
        let inner = try #require(slider(in: control))
        #expect(inner.isContinuous)

        inner.doubleValue = 0.5
        _ = inner.target?.perform(inner.action, with: inner)
        #expect(reported.last == 0.5)
        #expect(control.value == 0.5)
    }

    @Test("a toggle starts where it was told to and reports each flip")
    func toggleReportsChanges() throws {
        var reported: [Bool] = []
        let control = WindowOptionsToggle(title: "Blink caret", isOn: true) { reported.append($0) }
        #expect(control.isOn)
        #expect(labels(in: control).isEmpty)  // the title lives on the checkbox itself

        let inner = try #require(button(in: control))
        #expect(inner.title == "Blink caret")
        inner.state = .off
        _ = inner.target?.perform(inner.action, with: inner)
        #expect(reported == [false])
        #expect(control.isOn == false)
    }

    // MARK: Rebuilding

    /// A control can be moved by something other than itself — ⌘+ moves the
    /// text-size slider — and the body is built from a closure over live state,
    /// so the fix is to build it again rather than to reach in and set a value
    /// on a control the dialog owns.
    @Test("rebuilding a closed dialog does nothing")
    func rebuildOfAClosedDialogIsFree() {
        var builds = 0
        let options = WindowOptionsDialog(title: "Olylo Window") {
            builds += 1
            return []
        }
        options.rebuildControls()
        #expect(builds == 0)
        // The next open builds it anyway, which is why a closed dialog has
        // nothing to keep in step.
        _ = options.makeDialogWindow()
        #expect(builds == 1)
    }

    /// A host whose title can change — a pane named by whatever its content is
    /// showing — would otherwise keep the name it had at construction.
    @Test("renaming carries into the next dialog the gear raises")
    func titleChangeCarriesIntoTheNextDialog() {
        let options = WindowOptionsDialog(title: "Olylo Window") { [] }
        options.title = "Files"
        #expect(options.makeDialogWindow().title == "Files")
    }
}
