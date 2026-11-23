import XCTest
import AppKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
final class CLISettingsPanelTests: XCTestCase {

    private func field(_ id: String, in view: NSView) -> NSTextField? {
        if let field = view as? NSTextField, field.accessibilityIdentifier() == id { return field }
        for sub in view.subviews { if let found = field(id, in: sub) { return found } }
        return nil
    }

    private func button(_ id: String, in view: NSView) -> NSButton? {
        if let button = view as? NSButton, button.accessibilityIdentifier() == id { return button }
        for sub in view.subviews { if let found = button(id, in: sub) { return found } }
        return nil
    }

    private func makePanel(status: AutomationServerStatus,
                           pasteboard: NSPasteboard = .general) -> CLISettingsPanelViewController {
        let panel = CLISettingsPanelViewController(status: status, pasteboard: pasteboard)
        _ = panel.view
        return panel
    }

    func testStatusLineNamesThePortAndRegistration() {
        let status = AutomationServerStatus()
        status.port = 51477
        status.isRegistered = false
        let panel = makePanel(status: status)
        let line = field("settings.automation.status", in: panel.view)
        XCTAssertEqual(line?.stringValue, "Listening on port 51477. Not registered with Claude Code.")
        status.isRegistered = true
        XCTAssertEqual(line?.stringValue, "Listening on port 51477. Registered with Claude Code.")
    }

    func testFailureReasonIsTheStatusLine() {
        let status = AutomationServerStatus()
        status.failureReason = "could not write /x/mcp-token: Permission denied"
        let panel = makePanel(status: status)
        XCTAssertEqual(field("settings.automation.status", in: panel.view)?.stringValue,
                       "Not running: could not write /x/mcp-token: Permission denied")
    }

    func testCopyPutsTheClaudeCommandOnThePasteboard() {
        let status = AutomationServerStatus()
        let command = MCPRegistration.claudeCommand(channel: .dev, adhdPath: "/opt/adhd/adhd")
        status.port = MCPRegistration.Channel.dev.port
        status.command = command
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("adkitchen.tests." + UUID().uuidString))
        addTeardownBlock { pasteboard.releaseGlobally() }
        let panel = makePanel(status: status, pasteboard: pasteboard)
        let copy = button("settings.automation.copy-command", in: panel.view)
        XCTAssertNotNil(copy)
        copy?.performClick(nil)
        XCTAssertEqual(pasteboard.string(forType: .string), command)
    }
}
