import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("ClaudeHookConfigurationConformance")
struct ClaudeHookConfigurationConformanceTests {

    private func stenographer(
        name: String = "stenographer",
        hookBinaryPath: String = "/h/steno",
        settingsURL: URL = URL(fileURLWithPath: "/tmp/never-written/settings.json"),
        bundledDispatcher: URL? = nil,
        hookedEvents: [HookEventType] = ClaudeHookConfiguration.defaultHookedEvents
    ) -> ClaudeHookConfiguration {
        ClaudeHookConfiguration(
            name: name,
            marker: "# stenographer-hook",
            hookBinaryPath: hookBinaryPath,
            dropDirectory: "~/.claude/stenographer-events",
            settingsURL: settingsURL,
            bundledDispatcher: bundledDispatcher,
            hookedEvents: hookedEvents)
    }

    @Test("V1: the initializer defaults the arguments, tap-only, dispatcher and legacy")
    func testV1_initializerDefaults() {
        let config = ClaudeHookConfiguration(
            name: "stenographer",
            marker: "# stenographer-hook",
            hookBinaryPath: "/h/steno",
            dropDirectory: "~/.claude/stenographer-events")

        #expect(config.hookArguments == ["hook", "--event"])
        #expect(config.statusLineArguments == ["statusline"])
        #expect(config.statusLineTapOnly == false)
        #expect(config.bundledDispatcher == nil)
        #expect(config.legacy == LegacyHookForms.none)
        #expect(config.settingsURL == ClaudeHookConfiguration.defaultSettingsURL)
        #expect(config.hookedEvents == ClaudeHookConfiguration.defaultHookedEvents)
    }

    @Test("V2: the lock and status-line entry names default from the name")
    func testV2_derivedNameDefaults() {
        let config = stenographer()

        #expect(config.ownLockName == ".stenographer-hooks.lock")
        #expect(config.statusLineEntryName == "stenographer")
    }

    @Test("V3: explicit lock and entry names are stored unchanged")
    func testV3_explicitNamesStored() {
        let config = ClaudeHookConfiguration(
            name: "adkd",
            marker: "# adkd-hook",
            hookBinaryPath: "/h/adk",
            dropDirectory: "~/.claude/adkd-events",
            ownLockName: ".adkd-hooks.lock",
            statusLineEntryName: "adkd")

        #expect(config.ownLockName == ".adkd-hooks.lock")
        #expect(config.statusLineEntryName == "adkd")
        #expect(config.name == "adkd")
    }

    @Test("V4: the helper path from a daemon under Contents/MacOS")
    func testV4_helperFromMacOSDirectory() {
        let executable = URL(fileURLWithPath: "/Applications/Stenographer.app/Contents/MacOS/stenographerd")

        #expect(ClaudeHookConfiguration.bundledHelperPath(named: "steno", executable: executable)
                == "/Applications/Stenographer.app/Contents/Helpers/steno")
    }

    @Test("V5: the helper path from the helper's own directory")
    func testV5_helperFromHelpersDirectory() {
        let executable = URL(fileURLWithPath: "/Applications/Stenographer.app/Contents/Helpers/steno")

        #expect(ClaudeHookConfiguration.bundledHelperPath(named: "steno", executable: executable)
                == "/Applications/Stenographer.app/Contents/Helpers/steno")
    }

    @Test("V6: a symlinked executable resolves to the real bundle")
    func testV6_symlinkResolvesToRealBundle() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("hook-config-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let macOS = root.appendingPathComponent("real/Stenographer.app/Contents/MacOS")
        try FileManager.default.createDirectory(at: macOS, withIntermediateDirectories: true)
        let real = macOS.appendingPathComponent("stenographerd")
        try Data().write(to: real)
        let link = root.appendingPathComponent("stenographerd")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: real)

        let path = ClaudeHookConfiguration.bundledHelperPath(named: "steno", executable: link)

        let expected = real.resolvingSymlinksInPath().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Helpers/steno").path
        #expect(path == expected)
    }

    @Test("V7: the dispatcher is derived from the helper path")
    func testV7_dispatcherDerived() {
        let config = stenographer(hookBinaryPath: "/Applications/Stenographer.app/Contents/Helpers/steno")

        #expect(config.resolvedBundledDispatcher
                == URL(fileURLWithPath: "/Applications/Stenographer.app/Contents/Resources/dispatch.sh"))
    }

    @Test("V8: an explicit dispatcher wins")
    func testV8_dispatcherExplicit() throws {
        let dispatcher = try #require(URL(string: "file:///tmp/d.sh"))

        #expect(stenographer(bundledDispatcher: dispatcher).resolvedBundledDispatcher == dispatcher)
    }

    @Test("V9: the default hooked events exclude the excluded types, in allCases order")
    func testV9_defaultHookedEvents() {
        let expected = HookEventType.allCases.filter {
            !ClaudeHookInstaller.excludedEventTypes.contains($0.rawValue)
        }

        let events = ClaudeHookConfiguration.defaultHookedEvents

        #expect(events == expected)
        #expect(events.contains(.preToolUse))
        #expect(!events.contains(.worktreeCreate))
        #expect(!events.contains(.worktreeRemove))
        #expect(!events.contains(.statusLine))
    }

    @Test("V10: an explicit hooked-events list is kept as given")
    func testV10_explicitHookedEventsKept() {
        let config = stenographer(hookedEvents: [.stop, .statusLine])

        #expect(config.hookedEvents == [.stop, .statusLine])
    }

    @Test("V11: LegacyHookForms defaults recognise nothing and equal none")
    func testV11_legacyDefaults() {
        let legacy = LegacyHookForms()

        #expect(legacy.httpHookURLBase == nil)
        #expect(legacy.captureScriptName == nil)
        #expect(legacy.captureScriptSecondLinePrefixes.isEmpty)
        #expect(legacy.statusLineCommands.isEmpty)
        #expect(legacy.statusLineCommandSuffixes.isEmpty)
        #expect(legacy == LegacyHookForms.none)
    }

    @Test("V12: configurations differing only in settingsURL are not equal")
    func testV12_equalityComparesSettingsURL() {
        let first = stenographer(settingsURL: URL(fileURLWithPath: "/tmp/one/settings.json"))
        let second = stenographer(settingsURL: URL(fileURLWithPath: "/tmp/two/settings.json"))

        #expect(first != second)
        #expect(first == stenographer(settingsURL: URL(fileURLWithPath: "/tmp/one/settings.json")))
    }

    @Test("V13: an empty name is accepted and concatenated into the lock name")
    func testV13_noInputValidation() {
        let config = stenographer(name: "")

        #expect(config.name.isEmpty)
        #expect(config.ownLockName == ".-hooks.lock")
    }

    @Test("V14: the default settings URL is .claude/settings.json under the home directory")
    func testV14_defaultSettingsURL() {
        let expected = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")

        #expect(ClaudeHookConfiguration.defaultSettingsURL == expected)
        #expect(ClaudeHookConfiguration.defaultSettingsURL.path.hasSuffix("/.claude/settings.json"))
    }

    @Test("V15: the marker is stored exactly as given")
    func testV15_markerStoredExactly() {
        let config = ClaudeHookConfiguration(
            name: "n",
            marker: "# {{app_name_lower}}-hook",
            hookBinaryPath: "/h",
            dropDirectory: "~/d")

        #expect(config.marker == "# {{app_name_lower}}-hook")
    }

    @Test("V16: the four required fields are stored exactly as given")
    func testV16_requiredFieldsStored() {
        let config = ClaudeHookConfiguration(name: "n", marker: "m", hookBinaryPath: "/h", dropDirectory: "~/d")

        #expect(config.name == "n")
        #expect(config.marker == "m")
        #expect(config.hookBinaryPath == "/h")
        #expect(config.dropDirectory == "~/d")
    }

    @Test("V17: the default executable traps without a main executable URL",
          .disabled("A trap would crash the test runner, and the runner always has a main executable URL"))
    func testV17_defaultExecutableTraps() {}

    @Test("V18: the settings URL follows the home directory at each read",
          .disabled("The home directory cannot be changed in the test process without touching the real user"))
    func testV18_settingsURLResolvedPerRead() {}

    @Test("V19: renaming a configuration does not recompute the derived names")
    func testV19_derivedFieldsNotRecomputed() {
        var config = stenographer(name: "a")

        config.name = "b"

        #expect(config.name == "b")
        #expect(config.ownLockName == ".a-hooks.lock")
        #expect(config.statusLineEntryName == "a")
    }

    @Test("V20: construction and derived properties create no file")
    func testV20_noSideEffects() {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("hook-config-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let settings = root.appendingPathComponent("settings.json")

        let config = stenographer(settingsURL: settings)
        _ = config.resolvedBundledDispatcher
        _ = config.ownLockName
        _ = ClaudeHookConfiguration.defaultSettingsURL
        _ = ClaudeHookConfiguration.defaultHookedEvents

        #expect(!FileManager.default.fileExists(atPath: root.path))
    }

    @Test("V21: an executable outside a bundle still yields a sibling Helpers path")
    func testV21_noParentBundleCheck() {
        let executable = URL(fileURLWithPath: "/usr/local/bin/tool")

        #expect(ClaudeHookConfiguration.bundledHelperPath(named: "tool", executable: executable)
                == "/usr/local/Helpers/tool")
    }

    @Test("V22: the dispatcher derived from a shallow helper path")
    func testV22_dispatcherFromShallowPath() {
        let config = stenographer(hookBinaryPath: "/steno")

        #expect(config.resolvedBundledDispatcher == URL(fileURLWithPath: "/Resources/dispatch.sh"))
    }
}
