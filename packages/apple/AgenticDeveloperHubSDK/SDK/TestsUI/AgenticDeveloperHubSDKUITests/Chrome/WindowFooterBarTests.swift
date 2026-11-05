import Testing
import AppKit
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// The strip across the bottom of a document window. It takes a string; it
/// does not know what a pane is, which is the whole reason it can live here.
@MainActor
@Suite("Window footer bar")
struct WindowFooterBarTests {

    @Test("the status it is given is the status it shows")
    func statusRoundTrips() {
        let footer = WindowFooterBar(accessibilityPrefix: "project.footer")
        footer.status = "api-server › Backend › Files › src/main.swift"
        #expect(footer.statusLabel.stringValue == "api-server › Backend › Files › src/main.swift")
    }

    /// A long path truncates rather than growing the window, so the full text
    /// has to be reachable some other way.
    @Test("a long status is also the tooltip, so it survives truncation")
    func longStatusIsAlsoATooltip() {
        let footer = WindowFooterBar(accessibilityPrefix: "project.footer")
        let path = String(repeating: "segment › ", count: 40)
        footer.status = path
        #expect(footer.statusLabel.toolTip == path)
    }

    @Test("the status label is addressable")
    func statusLabelIsIdentified() {
        let footer = WindowFooterBar(accessibilityPrefix: "project.footer")
        #expect(footer.statusLabel.accessibilityIdentifier() == "project.footer.status")
    }

    @Test("the trailing slot starts empty and accepts views")
    func trailingSlot() {
        let footer = WindowFooterBar(accessibilityPrefix: "project.footer")
        #expect(footer.trailingAccessories.isEmpty)

        let badge = NSButton(title: "3", target: nil, action: nil)
        footer.trailingAccessories = [badge]
        #expect(footer.trailingAccessories.count == 1)
        #expect(footer.trailingAccessories.first === badge)

        footer.trailingAccessories = []
        #expect(footer.trailingAccessories.isEmpty)
        #expect(badge.superview == nil)
    }

    @Test("a vertical separator constrains its width, a horizontal one its height")
    func separatorAxis() {
        let horizontal = ThemedSeparatorView()
        #expect(horizontal.constraints.contains { $0.firstAttribute == .height && $0.constant == 1 })

        let vertical = ThemedSeparatorView(axis: .vertical)
        #expect(vertical.constraints.contains { $0.firstAttribute == .width && $0.constant == 1 })
        #expect(!vertical.constraints.contains { $0.firstAttribute == .height })
    }
}
