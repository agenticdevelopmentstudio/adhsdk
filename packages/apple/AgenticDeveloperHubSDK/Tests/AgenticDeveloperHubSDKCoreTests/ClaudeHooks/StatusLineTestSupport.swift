@testable import AgenticDeveloperHubSDKCore
import Foundation

/// Fixtures shared by the status-line and HookInstaller tests. Each one
/// throws, so a fixture that cannot be made fails the test that needed it
/// instead of quietly turning into a missing dispatcher.
enum StatusLineTestSupport {

    /// A stand-in for the dispatcher a bundle carries: a script whose second
    /// line is the version line. The default is the first `dispatch.py`.
    static func makeBundledDispatcher(in directory: URL,
                                      version: Int = ClaudeStatusLine.firstPythonVersion) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("bundled-dispatch-\(version).py")
        try "#!/usr/bin/env python3\n# claudehelpers-statusline-dispatch \(version)\n"
            .write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// The adtoolkit checkout, which owns claudehelpers' status-line
    /// dispatcher and its contract. `ADTOOLKIT_CHECKOUT` names one; otherwise
    /// it is the checkout adtoolkit's `./install` recorded in `~/.adtoolkitrc`
    /// (`# Checkout: <path>`), read as `./install`'s `adtoolkit_checkout`
    /// reads it: the first ten lines, blank ones counted, a leading `~` the
    /// home directory, a relative path naming none. Nil when neither says,
    /// and `requireAdtoolkit` then fails naming the fix.
    static var adtoolkitRoot: URL? {
        if let named = ProcessInfo.processInfo.environment["ADTOOLKIT_CHECKOUT"], !named.isEmpty {
            return URL(fileURLWithPath: named, isDirectory: true)
        }
        let home = FileManager.default.homeDirectoryForCurrentUser
        let rcFile = home.appendingPathComponent(".adtoolkitrc")
        guard let text = try? String(contentsOf: rcFile, encoding: .utf8) else { return nil }
        let prefix = "# Checkout: "
        for line in text.components(separatedBy: "\n").prefix(10) where line.hasPrefix(prefix) {
            var path = line.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
            if path == "~" || path.hasPrefix("~/") { path = home.path + path.dropFirst() }
            return path.hasPrefix("/") ? URL(fileURLWithPath: path, isDirectory: true) : nil
        }
        return nil
    }

    /// The dispatcher version whose contract these tests were written
    /// against. The tests read adtoolkit's checkout as it is on disk, so a
    /// newer contract there fails them as a version mismatch, naming both,
    /// rather than as whichever case happened to change.
    static let adtoolkitContractVersion = 7

    /// adtoolkit's path to claudehelpers, under its checkout.
    private static func inAdtoolkit(_ relative: String) -> URL {
        (adtoolkitRoot ?? URL(fileURLWithPath: "/nonexistent-adtoolkit", isDirectory: true))
            .appendingPathComponent("tools/claudehelpers").appendingPathComponent(relative)
    }

    /// claudehelpers' status-line directory in adtoolkit, which holds the
    /// dispatcher and the settings contract.
    static var dispatcherSource: URL { inAdtoolkit("lib/statuslinedispatcher") }

    /// The dispatcher adtoolkit installs and a bundle carries.
    static var realDispatcher: URL { dispatcherSource.appendingPathComponent("dispatch.py") }

    /// The conformance fixtures both claudehelpers' pytest suite and these
    /// tests run, so the Swift and Python halves agree case for case.
    static var conformanceFixtures: URL { inAdtoolkit("tests/fixtures/statusline_conformance.json") }

    /// Fails with a message that names the fix when adtoolkit is not
    /// installed, instead of a bare missing-file error, and when its
    /// dispatcher carries a contract other than `adtoolkitContractVersion`.
    static func requireAdtoolkit(_ url: URL) throws -> URL {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AdtoolkitMissing(path: url.path)
        }
        let dispatcher = realDispatcher
        guard let text = try? String(contentsOf: dispatcher, encoding: .utf8) else {
            throw AdtoolkitMissing(path: dispatcher.path)
        }
        let version = ClaudeStatusLine.dispatcherVersion(text)
        guard version == adtoolkitContractVersion else {
            throw AdtoolkitContractChanged(path: dispatcher.path, found: version)
        }
        return url
    }

    struct AdtoolkitContractChanged: Error, CustomStringConvertible {
        let path: String
        let found: Int?
        var description: String {
            let found = self.found.map(String.init) ?? "no version line"
            return "\(path) carries status-line contract \(found), but these tests follow "
                + "\(StatusLineTestSupport.adtoolkitContractVersion): bring ClaudeStatusLine and its "
                + "tests to the new contract, or use the adtoolkit that matches"
        }
    }

    struct AdtoolkitMissing: Error, CustomStringConvertible {
        let path: String
        var description: String {
            "\(path) is missing: install adtoolkit (run ./install in its checkout, which records it "
                + "in ~/.adtoolkitrc), or name a checkout with ADTOOLKIT_CHECKOUT"
        }
    }
}

/// `statusline_conformance.json`, the cases claudehelpers' Python and this
/// Swift code must agree on.
struct StatusLineConformance: Decodable {

    struct Quote: Decodable { let word: String; let quoted: String }
    struct CommandCase: Decodable { let command: String; let expected: Bool }
    struct NameCase: Decodable { let name: String; let expected: Bool }
    struct VersionCase: Decodable { let text: String; let version: Int? }
    /// `entries` and `renderers` are `[kind, name, command]` and `[name, command]`.
    struct AdoptCase: Decodable {
        let about: String
        let entries: [[String]]
        let command: String
        let name: String?
        let renderers: [[String]]
    }
    /// `slot` is `removed`, `dispatcher`, or the command handed back.
    struct ReleaseCase: Decodable {
        let about: String
        let remaining: [[String]]
        let slot: String
    }

    let shellQuote: [Quote]
    let isDispatcherCommand: [CommandCase]
    let isAdoptedName: [NameCase]
    let isValidName: [NameCase]
    let dispatcherVersion: [VersionCase]
    let adopt: [AdoptCase]
    let release: [ReleaseCase]

    static func load() throws -> StatusLineConformance {
        let url = try StatusLineTestSupport.requireAdtoolkit(StatusLineTestSupport.conformanceFixtures)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(StatusLineConformance.self, from: Data(contentsOf: url))
    }

    /// Writes one `[kind, name, command]` entry file the way another tool would.
    static func write(_ entry: [String], under directory: URL) throws {
        let url = directory.appendingPathComponent(entry[0]).appendingPathComponent(entry[1])
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data((entry[2] + "\n").utf8).write(to: url)
    }
}

// MARK: - Hook configurations used across the hook tests

extension ClaudeHookConfiguration {

    /// The values a macOS menu-bar session daemon installs with: the reference
    /// fixture whose rendered commands and settings the installer tests pin.
    static func stenographerFixture(
        helperPath: String = "/Applications/Stenographer.app/Contents/Helpers/steno",
        settingsURL: URL,
        dropDirectory: String = "~/.claude/stenographer-events",
        bundledDispatcher: URL? = nil
    ) -> ClaudeHookConfiguration {
        let binDirectory = "/usr/local/bin"
        return ClaudeHookConfiguration(
            name: "stenographer",
            marker: "# stenographer-hook",
            hookBinaryPath: helperPath,
            dropDirectory: dropDirectory,
            settingsURL: settingsURL,
            ownLockName: ".stenographer-hooks.lock",
            statusLineEntryName: "stenographer",
            bundledDispatcher: bundledDispatcher,
            legacy: LegacyHookForms(
                httpHookURLBase: "http://127.0.0.1:22847/hook",
                captureScriptName: "stenographer-capture.py",
                captureScriptSecondLinePrefixes: [
                    "\"\"\"stenographer-capture.py \u{2014} the hook entry point that survives an install.",
                    "\"\"\"stenographer-capture.py \u{2014} the hook entry point stenographer registers."
                ],
                statusLineCommands: [
                    "\(binDirectory)/steno statusline",
                    "\(binDirectory)/steno statusline --capture-only",
                    "stenographer statusline",
                    "\(binDirectory)/stenographer statusline",
                    "snog statusline",
                    "\(binDirectory)/snog statusline"
                ],
                statusLineCommandSuffixes: ["statusline.dispatcher"]))
    }

    /// A second daemon's configuration, built from the same values as the Kitchen's
    /// `ClaudeHookConfiguration.adkd()`: its own marker, helper and drop
    /// directory, a tap-only status line and no legacy forms.
    static func adkdFixture(
        helperPath: String = "/Applications/Kitchen.app/Contents/Helpers/adk",
        settingsURL: URL,
        dropDirectory: String = "~/.claude/adkd-events",
        bundledDispatcher: URL? = nil
    ) -> ClaudeHookConfiguration {
        ClaudeHookConfiguration(
            name: "adkd",
            marker: "# adkd-hook",
            hookBinaryPath: helperPath,
            hookArguments: ["hook", "--event"],
            statusLineArguments: ["statusline"],
            statusLineTapOnly: true,
            dropDirectory: dropDirectory,
            settingsURL: settingsURL,
            ownLockName: ".adkd-hooks.lock",
            statusLineEntryName: "adkd",
            bundledDispatcher: bundledDispatcher,
            legacy: .none)
    }
}

extension ClaudeHookInstaller {

    /// Mirrors the argument shape the installer tests were written against.
    convenience init(settingsURL: URL, dropDirectory: String, stenoPath: String,
                     bundledDispatcher: URL? = nil, lockTimeout: TimeInterval = 5,
                     stenoIsExecutable: @escaping @Sendable (String) -> Bool
                        = ClaudeHookInstaller.defaultHelperIsExecutable) {
        self.init(
            configuration: .stenographerFixture(helperPath: stenoPath, settingsURL: settingsURL,
                                                dropDirectory: dropDirectory,
                                                bundledDispatcher: bundledDispatcher),
            lockTimeout: lockTimeout, helperIsExecutable: stenoIsExecutable)
    }
}
