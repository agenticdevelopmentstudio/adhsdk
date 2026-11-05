import Testing
import AppKit
import Foundation
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

@MainActor
@Suite("ToolCallPillView")
struct ToolCallPillViewTests {

    private func makeManager(activeThemeID: String) -> ThemeManager {
        ThemeManager(storage: InMemoryThemeStorage(activeThemeID: activeThemeID))
    }

    private func invocation(_ name: String = "search") -> FixtureCommandInvocation {
        FixtureCommandInvocation(id: "inv-1", commandName: name, invokerID: "persona-1")
    }

    @Test("a running command reads .info and names the command")
    func runningIsInfo() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let palette = ThemePaletteObserver.currentPalette
        let pill = ToolCallPillView(activity: CommandActivity(invocation: invocation("grep")))

        #expect(pill.titleText.contains("grep"))
        #expect(pill.titleColor == palette.nsColor(.info))
        #expect(pill.layer?.borderColor == palette.nsColor(.info).cgColor)
    }

    @Test("a successful result reads .success")
    func successIsSuccess() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let palette = ThemePaletteObserver.currentPalette
        let activity = CommandActivity(
            invocation: invocation(),
            result: FixtureCommandResult(invocationID: "inv-1", ok: true))
        let pill = ToolCallPillView(activity: activity)

        #expect(pill.titleColor == palette.nsColor(.success))
        #expect(pill.layer?.borderColor == palette.nsColor(.success).cgColor)
    }

    @Test("a failed result reads .danger and shows the error message")
    func failureIsDanger() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let palette = ThemePaletteObserver.currentPalette
        let activity = CommandActivity(
            invocation: invocation(),
            result: FixtureCommandResult(invocationID: "inv-1", ok: false, errorMessage: "permission denied"))
        let pill = ToolCallPillView(activity: activity)

        #expect(pill.titleColor == palette.nsColor(.danger))
        #expect(pill.layer?.borderColor == palette.nsColor(.danger).cgColor)
        #expect(pill.titleText.contains("permission denied"))
    }

    @Test("repaints when the active theme changes")
    func repaintsOnThemeChange() {
        let manager = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let pill = ToolCallPillView(activity: CommandActivity(invocation: invocation()))

        let before = pill.titleColor
        manager.selectTheme(id: BuiltInThemes.dracula.id)
        let after = pill.titleColor

        #expect(before != nil)
        #expect(before != after)
    }
}
