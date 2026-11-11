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
    ///
    /// What it reads is fixed for the whole process, for every Chrome pane
    /// at once, so it reads `processSettings(settings)`: a pane's layered
    /// store hands in the global values beneath it, never the overrides of
    /// whichever pane happened to start Chromium first.
    @discardableResult
    public static func start(settings: SettingsStore = UserSettings.shared) -> Error? {
        let runtime = ChromiumRuntime.shared
        if runtime.isRunning { return nil }
        let settings = processSettings(settings)
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

    /// The store beneath every pane override: `settings` with each
    /// `LayeredSettingsStore` peeled back to its fallback.
    static func processSettings(_ settings: SettingsStore) -> SettingsStore {
        var store = settings
        while let layered = store as? LayeredSettingsStore { store = layered.fallback }
        return store
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
        configuration.extensionUpdateFrequency =
            settings.get(UserSettings.browserChromeExtensionUpdateInterval).seconds
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

    /// The home the profile root hangs off. The host sets it before the
    /// first Chromium use, so a run under a scratch home (`APP_TEST_HOME`)
    /// gets a scratch profile instead of the developer's own. It defaults to
    /// the real home, which `homeDirectoryForCurrentUser` reads from the
    /// password database rather than `$HOME`.
    public static var homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser

    static func profileDirectory() -> URL {
        var root = AppStorageLocation.directory(inHome: homeDirectory)
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

    /// Adds the Chromium jar directories to the reconciler's sweep, and their
    /// site data to the project jars panel, once.
    static func registerJarStores() {
        guard !registeredJarStores else { return }
        registeredJarStores = true
        BrowserJarReconciler.registerEngineStores(jarStores)
        BrowserJarEngines.register(ChromiumJarSiteData())
    }
}

/// A Chrome jar's site data, for the project jars panel: the sites its
/// profile holds cookies for, and removing them. Chromium is started for a
/// jar that has a profile, since its storage is Chromium's to open, and left
/// alone for one that has none.
///
/// Cookies are what sign a pane in, and all CEF can reach without a page:
/// clearing a whole jar also empties its HTTP cache and saved HTTP sign-ins,
/// but local storage a site wrote stays until the jar itself is removed.
@MainActor
final class ChromiumJarSiteData: BrowserJarEngineSiteData {

    let siteDataLabel = "Chrome: Cookies"

    func sites(inJar jarID: UUID) async -> [String] {
        guard let path = profilePath(for: jarID) else { return [] }
        let domains = await withCheckedContinuation { (continuation: CheckedContinuation<[String], Never>) in
            ChromiumRuntime.shared.cookieDomains(inProfileAtPath: path) { continuation.resume(returning: $0) }
        }
        return Self.sites(fromCookieDomains: domains)
    }

    func removeSite(_ site: String, fromJar jarID: UUID) async {
        await delete(site, fromJar: jarID)
    }

    func removeAll(fromJar jarID: UUID) async {
        await delete(nil, fromJar: jarID)
    }

    /// Folds cookie domains into sites: a domain under another listed one
    /// (`gist.github.com` under `github.com`) is that site, which is how
    /// WebKit's records group them. Removing a site removes its domain and
    /// every domain under it, so the fold and the removal agree.
    nonisolated static func sites(fromCookieDomains domains: [String]) -> [String] {
        let unique = Set(domains.map { $0.lowercased() })
        return unique.filter { domain in
            !unique.contains { $0 != domain && domain.hasSuffix("." + $0) }
        }.sorted()
    }

    private func delete(_ site: String?, fromJar jarID: UUID) async {
        guard let path = profilePath(for: jarID) else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ChromiumRuntime.shared.deleteSiteData(site, inProfileAtPath: path) { continuation.resume() }
        }
    }

    /// The jar's profile path, with Chromium running, or nil when the jar has
    /// no profile or Chromium will not start.
    private func profilePath(for jarID: UUID) -> String? {
        let directory = ChromiumLauncher.jarProfileDirectory(for: jarID)
        guard FileManager.default.fileExists(atPath: directory.path),
              ChromiumLauncher.start() == nil else { return nil }
        return directory.path
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

    // MARK: Extensions

    /// One hidden extensions page per profile for the whole process — every
    /// pane's maintenance and the Settings window's share it — kept until the
    /// last open topic closes, so a list followed by a toggle does not load
    /// Chrome's page twice and two topics on one profile drive one page.
    private static let extensionManagers = BrowserExtensionManagerCache<ChromiumExtensionManager>(
        hasFailed: { $0.pageFailed }, close: { $0.close() })

    public func extensions(in profile: BrowserExtensionProfile) async throws -> [BrowserExtension] {
        try await extensionManager(for: profile).list()
    }

    public func setExtension(_ id: String, enabled: Bool, in profile: BrowserExtensionProfile) async throws {
        try await extensionManager(for: profile).setEnabled(id, enabled: enabled)
    }

    public func removeExtension(_ id: String, in profile: BrowserExtensionProfile) async throws {
        try await extensionManager(for: profile).remove(id)
    }

    public func checkForExtensionUpdates(in profile: BrowserExtensionProfile) async throws {
        try await extensionManager(for: profile).updateAll()
    }

    /// This topic is done; the pages close once no other topic holds them.
    public func endExtensionManagement() {
        Self.extensionManagers.release(holder: self)
    }

    private func extensionManager(for profile: BrowserExtensionProfile) throws -> ChromiumExtensionManager {
        try Self.extensionManagers.manager(for: profile, holder: self) {
            if let error = ChromiumLauncher.start(settings: settings) {
                throw BrowserExtensionError.unavailable(error.localizedDescription)
            }
            return try ChromiumExtensionManager(profile: profile)
        }
    }
}
