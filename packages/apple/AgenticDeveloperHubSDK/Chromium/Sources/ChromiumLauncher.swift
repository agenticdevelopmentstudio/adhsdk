//
//  ChromiumLauncher.swift
//  AgenticDeveloperHubSDKChromium
//

import AppKit
import CryptoKit
import os
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKMacOS

/// Starts the process's one Chromium the first time a Chrome pane or the
/// Chrome settings topic needs it, from the browser settings Chromium reads
/// only when it starts.
///
/// Where everything is:
///
/// - **The helper and the framework** are in the app's Frameworks folder,
///   put there by `tools/apple/cef.py embed`. The helper is named after the
///   app's executable, because Chromium finds the (GPU), (Renderer),
///   (Plugin) and (Alerts) variants by appending to that name.
/// - **The profile** is `Chromium/Default` in the app's storage directory,
///   beside its databases. A Debug build keeps one per app bundle, under a
///   hash of the bundle's path: Debug runs a copy per worktree side by side,
///   and Chromium refuses a profile directory another running copy holds.
@MainActor
public enum ChromiumLauncher {

    private static let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "Chromium")

    /// Starts Chromium if it is not running. `nil` when it is running after
    /// the call; otherwise why it is not, which every later call repeats.
    @discardableResult
    public static func start(settings: SettingsStore = UserSettings.shared) -> Error? {
        let runtime = ChromiumRuntime.shared
        if runtime.isRunning { return nil }
        let configuration = makeConfiguration(settings: settings)
        do {
            try runtime.start(with: configuration)
            runtime.acceptsCookies = settings.get(UserSettings.browserAcceptsCookies)
            logger.info("Chromium \(ChromiumRuntime.chromiumVersion, privacy: .public) started")
            return nil
        } catch {
            logger.error("Chromium did not start: \(error.localizedDescription, privacy: .public)")
            return error
        }
    }

    static func makeConfiguration(settings: SettingsStore) -> ChromiumRuntimeConfiguration {
        let configuration = ChromiumRuntimeConfiguration()
        let frameworks = URL(fileURLWithPath: Bundle.main.privateFrameworksPath ?? "")
        let executable = Bundle.main.executableURL?.lastPathComponent ?? AppStorageLocation.displayName
        let helper = "\(executable) Helper"
        configuration.helperPath = frameworks
            .appendingPathComponent("\(helper).app/Contents/MacOS/\(helper)").path
        configuration.frameworkPath = frameworks
            .appendingPathComponent("Chromium Embedded Framework.framework").path
        configuration.cachePath = profileDirectory().path
        let port = settings.get(UserSettings.browserChromeRemoteDebuggingPort)
        configuration.remoteDebuggingPort = BrowserSettings.chromeRemoteDebuggingPortRange.contains(port) ? port : 0
        configuration.hardwareAcceleration = settings.get(UserSettings.browserChromeHardwareAcceleration)
        configuration.autoplayPolicy = autoplayPolicy(settings.get(UserSettings.browserAutoplay))
        #if DEBUG
        configuration.developmentMode = true
        #endif
        return configuration
    }

    /// Chromium's `--autoplay-policy` for the Autoplay setting. "Never" is
    /// Chromium's strictest policy, which still lets a muted video play: it
    /// has no policy that stops one, and the Media topic says so.
    static func autoplayPolicy(_ policy: BrowserAutoplayPolicy) -> String {
        switch policy {
        case .allowed: "no-user-gesture-required"
        case .mutedOnly: "document-user-activation-required"
        case .never: "user-gesture-required"
        }
    }

    static func profileDirectory() -> URL {
        var root = AppStorageLocation.directory(inHome: FileManager.default.homeDirectoryForCurrentUser)
            .appendingPathComponent("Chromium")
        #if DEBUG
        let digest = SHA256.hash(data: Data(Bundle.main.bundlePath.utf8))
        let tag = digest.prefix(6).map { String(format: "%02x", $0) }.joined()
        root = root.appendingPathComponent("debug-\(tag)")
        #endif
        return root.appendingPathComponent("Default")
    }

    /// The root cache directory, `Default`'s parent: CEF's `root_cache_path`.
    static func rootCacheDirectory() -> URL {
        profileDirectory().deletingLastPathComponent()
    }

    /// The prefix that marks a jar's profile among the root's children.
    static let jarProfilePrefix = "Jar-"

    /// Where a worktree or pane jar keeps its Chromium profile: a direct
    /// child of the root cache directory, beside `Default`. CEF opens a disk
    /// profile only at the root or one level below it; anywhere deeper it
    /// falls back to an in-memory profile and nothing persists.
    public static func jarProfileDirectory(for jarID: UUID) -> URL {
        rootCacheDirectory().appendingPathComponent(jarProfilePrefix + jarID.uuidString)
    }

    /// The jar profiles beside `Default`, as the reconciler sweeps them:
    /// identifiers are the `Jar-<uuid>` directories, and removing one
    /// deletes it.
    static let jarStores = BrowserJarReconciler.DataStores(
        identifiers: {
            let names = (try? FileManager.default.contentsOfDirectory(atPath: rootCacheDirectory().path)) ?? []
            return names.compactMap { name in
                guard name.hasPrefix(jarProfilePrefix) else { return nil }
                return UUID(uuidString: String(name.dropFirst(jarProfilePrefix.count)))
            }
        },
        remove: { id in
            let directory = jarProfileDirectory(for: id)
            guard FileManager.default.fileExists(atPath: directory.path) else { return }
            try FileManager.default.removeItem(at: directory)
        }
    )

    private static var registeredJarStores = false

    /// Adds the Chromium jar directories to the reconciler's sweep, once.
    static func registerJarStores() {
        guard !registeredJarStores else { return }
        registeredJarStores = true
        BrowserJarReconciler.registerEngineStores(jarStores)
    }
}

/// The Chrome settings topic's view of Chromium: its version, and the cookie
/// jar every non-private Chrome pane shares.
@MainActor
public final class ChromiumMaintenance: BrowserEngineMaintenance {

    private let settings: SettingsStore

    public init(settings: SettingsStore = UserSettings.shared) {
        self.settings = settings
    }

    public var engineVersion: String {
        "\(ChromiumRuntime.chromiumVersion) (CEF \(ChromiumRuntime.cefVersion))"
    }

    /// Starts Chromium if no Chrome pane has yet, since its cookie store is
    /// Chromium's to open.
    public func removeAllCookies() async {
        guard ChromiumLauncher.start(settings: settings) == nil else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ChromiumRuntime.shared.deleteAllCookies { continuation.resume() }
        }
    }
}
