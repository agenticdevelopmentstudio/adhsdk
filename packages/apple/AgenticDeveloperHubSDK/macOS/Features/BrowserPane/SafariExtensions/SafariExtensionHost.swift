//
//  SafariExtensionHost.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import WebKit
import os

/// Whether Safari panes can run web extensions here, and where they keep
/// them. The app sets `homeDirectory` at launch; until it does, and on a
/// macOS older than 15.4 (where WebKit gained `WKWebExtensionController`),
/// Safari panes have no extensions and the settings topic is not shown.
@MainActor
public enum SafariExtensionSupport {
    /// The home the app's storage is under (`APP_TEST_HOME` in a scratch
    /// run), so a scratch home gets scratch extensions.
    public static var homeDirectory: URL?

    public static var isAvailable: Bool {
        guard homeDirectory != nil else { return false }
        if #available(macOS 15.4, *) { return true }
        return false
    }
}

/// One profile's web extensions, run by WebKit: a `WKWebExtensionController`
/// that every Safari pane on the profile's jar is built with, the extensions
/// installed into it, and the answers WebKit asks the app for — which
/// windows and tabs there are, where a popup goes, whether a permission is
/// allowed.
///
/// One host per profile, kept for the life of the app, because WebKit's
/// controller is what a web view's configuration names and a web view
/// cannot change controllers once made. The extensions themselves are
/// Chrome Web Store packages (`WebStoreExtension`), unpacked into the
/// profile's `SafariExtensionLibrary`; what the person allowed each of them
/// is written back to its record whenever WebKit reports a change, because
/// WebKit forgets grants across launches.
@available(macOS 15.4, *)
@MainActor
public final class SafariExtensionHost: NSObject {

    /// Posted (object: the host) when an extension was installed, removed,
    /// turned on or off, or finished loading.
    public static let didChangeNotification = Notification.Name("SafariExtensionHostDidChange")
    /// Posted (object: the host) when an extension's toolbar action changed:
    /// its icon, label, badge or whether it is enabled.
    public static let actionsDidChangeNotification = Notification.Name("SafariExtensionHostActionsDidChange")

    /// The fixed identifier of the global profile's controller, whose
    /// extension storage WebKit keeps under it. A jar's controller uses the
    /// jar's own UUID, so its extension storage goes with the jar's.
    static let globalControllerID = UUID(uuidString: "5AFE5AFE-0000-4000-8000-0000000000C1")!

    private static var hosts: [BrowserExtensionProfile: SafariExtensionHost] = [:]

    /// The host for a pane's jar, made on first use; nil for a jar kept in
    /// memory (private browsing, a jar that failed closed) and before the
    /// app has said where extensions live.
    public static func host(for jar: BrowserResolvedJar) -> SafariExtensionHost? {
        guard let profile = BrowserExtensionProfile(jar) else { return nil }
        return host(for: profile)
    }

    /// Whether `jar` is private browsing: no jar at all, rather than one that
    /// failed closed.
    static func isPrivateBrowsing(_ jar: BrowserResolvedJar) -> Bool {
        jar.jar == nil && !jar.isFallback
    }

    /// The host whose extensions run in a pane on `jar`: the jar's own, and
    /// for private browsing the global profile's, where only the extensions
    /// allowed in private browsing reach the pane. Nil for a jar that failed
    /// closed.
    public static func runningHost(for jar: BrowserResolvedJar) -> SafariExtensionHost? {
        if isPrivateBrowsing(jar) { return host(for: BrowserExtensionProfile.global) }
        return host(for: jar)
    }

    /// The host for `profile`, made on first use.
    public static func host(for profile: BrowserExtensionProfile) -> SafariExtensionHost? {
        guard let home = SafariExtensionSupport.homeDirectory else { return nil }
        if let host = hosts[profile] { return host }
        let host = SafariExtensionHost(
            profile: profile,
            library: SafariExtensionLibrary(root: SafariExtensionLibrary.root(inHome: home, profile: profile)))
        hosts[profile] = host
        host.loadInstalled()
        return host
    }

    public let profile: BrowserExtensionProfile
    public let controller: WKWebExtensionController
    let library: SafariExtensionLibrary

    /// Why the profile's records could not be read. Nothing is saved while
    /// it is set, so a file that did not decode is never overwritten.
    public private(set) var libraryError: String?
    /// Whether the installed extensions are still being read.
    public private(set) var isLoading = false

    private var entries: [Entry] = []
    private let windows = NSHashTable<SafariExtensionWindow>.weakObjects()
    private weak var lastFocusedWindow: SafariExtensionWindow?
    private let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "SafariExtensions")

    /// One installed extension: its record, what WebKit made of its files,
    /// and its context while it is on.
    private final class Entry {
        var record: SafariExtensionRecord
        var webExtension: WKWebExtension?
        var context: WKWebExtensionContext?
        var failure: String?
        var observers: [NSObjectProtocol] = []
        /// A copied Safari extension whose app is no longer installed: kept
        /// off, whatever `record.isEnabled` says, until the app is back.
        var sourceMissing = false

        init(record: SafariExtensionRecord) {
            self.record = record
        }
    }

    init(profile: BrowserExtensionProfile, library: SafariExtensionLibrary) {
        self.profile = profile
        self.library = library
        let identifier: UUID
        let dataStore: WKWebsiteDataStore
        switch profile {
        case .global:
            identifier = Self.globalControllerID
            dataStore = .default()
        case .jar(let id):
            identifier = id
            dataStore = WKWebsiteDataStore(forIdentifier: id)
        }
        let configuration = WKWebExtensionController.Configuration(identifier: identifier)
        configuration.defaultWebsiteDataStore = dataStore
        controller = WKWebExtensionController(configuration: configuration)
        super.init()
        controller.delegate = self
    }

    // MARK: - Installed extensions

    /// The extensions as the settings topic lists them, in install order.
    public func extensions() -> [BrowserExtension] {
        entries.map { entry in
            let id = entry.record.id
            guard let webExtension = entry.webExtension else {
                return BrowserExtension(
                    id: id, name: id, version: "", summary: entry.failure ?? "Loading…",
                    isEnabled: false, isFromWebStore: entry.record.isFromWebStore, iconPNG: nil, optionsURL: nil,
                    sourceName: sourceName(of: entry))
            }
            let answered = Set(entry.record.grantedPermissions).union(entry.record.deniedPermissions)
            let unanswered = webExtension.requestedPermissions.contains { !answered.contains($0.rawValue) }
            return BrowserExtension(
                id: id,
                name: webExtension.displayName ?? id,
                version: webExtension.displayVersion ?? webExtension.version ?? "",
                summary: entry.failure ?? webExtension.displayDescription ?? "",
                isEnabled: entry.record.isEnabled && !entry.sourceMissing,
                needsPermissionReview: unanswered,
                isFromWebStore: entry.record.isFromWebStore,
                iconPNG: Self.png(webExtension.icon(for: CGSize(width: 32, height: 32))),
                optionsURL: entry.context?.optionsPageURL,
                sourceName: sourceName(of: entry))
        }
    }

    /// A copied Safari extension's app, and whether it is gone.
    private func sourceName(of entry: Entry) -> String? {
        guard let source = entry.record.appSource else { return nil }
        return entry.sourceMissing ? "\(source.appName) (app removed)" : "Safari (\(source.appName))"
    }

    /// The contexts of the extensions that are on, in install order: what a
    /// toolbar shows a button for.
    public var loadedContexts: [WKWebExtensionContext] {
        entries.compactMap(\.context)
    }

    public func isInstalled(_ id: String) -> Bool {
        entries.contains { $0.record.id == id }
    }

    /// The address of `id`'s options page, while it is on and has one.
    public func optionsURL(of id: String) -> URL? {
        entry(id)?.context?.optionsPageURL
    }

    /// Reads every installed extension and turns on the ones that were on.
    private func loadInstalled() {
        let records: [SafariExtensionRecord]
        do {
            records = try library.records()
        } catch {
            libraryError = "The installed extensions could not be read: \(error.localizedDescription)"
            logger.error("\(self.libraryError ?? "", privacy: .public)")
            return
        }
        entries = records.map(Entry.init(record:))
        guard !entries.isEmpty else { return }
        isLoading = true
        Task { @MainActor in
            for entry in entries { await open(entry) }
            isLoading = false
            changed()
            await checkForUpdates(presentingOn: nil)
        }
    }

    /// Reads `entry`'s files, and starts it when it is on.
    private func open(_ entry: Entry) async {
        do {
            entry.webExtension = try await WKWebExtension(resourceBaseURL: library.directory(of: entry.record.id))
            entry.failure = nil
            // Until the update check asks the registry, a copy whose app is
            // not where it was is taken as gone; the check finds a moved one.
            if let source = entry.record.appSource {
                entry.sourceMissing = !FileManager.default.fileExists(atPath: source.appexPath)
            }
            if entry.record.isEnabled { try start(entry) }
        } catch {
            entry.failure = error.localizedDescription
            let reason = error.localizedDescription
            logger.error("extension \(entry.record.id, privacy: .public) did not load: \(reason, privacy: .public)")
        }
    }

    /// Gives `entry` a context with its saved answers and loads it into the
    /// controller, which injects it into every page on the profile.
    private func start(_ entry: Entry) throws {
        guard let webExtension = entry.webExtension, entry.context == nil, !entry.sourceMissing else { return }
        let context = WKWebExtensionContext(for: webExtension)
        // Its storage is kept under this, and it is `chrome.runtime.id`.
        context.uniqueIdentifier = entry.record.id
        #if DEBUG
        context.isInspectable = true
        #endif
        apply(entry.record, to: context)
        try controller.load(context)
        entry.context = context
        entry.observers = observePermissions(of: context, id: entry.record.id)
    }

    private func stop(_ entry: Entry) {
        entry.observers.forEach(NotificationCenter.default.removeObserver)
        entry.observers = []
        guard let context = entry.context else { return }
        do { try controller.unload(context) } catch {
            let reason = error.localizedDescription
            logger.error("extension \(entry.record.id, privacy: .public) did not unload: \(reason, privacy: .public)")
        }
        entry.context = nil
    }

    private func apply(_ record: SafariExtensionRecord, to context: WKWebExtensionContext) {
        context.hasAccessToPrivateData = record.allowsPrivateBrowsing == true
        for permission in record.grantedPermissions {
            context.setPermissionStatus(.grantedExplicitly, for: WKWebExtension.Permission(rawValue: permission))
        }
        for permission in record.deniedPermissions {
            context.setPermissionStatus(.deniedExplicitly, for: WKWebExtension.Permission(rawValue: permission))
        }
        for origin in record.grantedOrigins {
            guard let pattern = try? WKWebExtension.MatchPattern(string: origin) else { continue }
            context.setPermissionStatus(.grantedExplicitly, for: pattern)
        }
        for origin in record.deniedOrigins where origin != SafariExtensionSettings.fileURLPattern {
            guard let pattern = try? WKWebExtension.MatchPattern(string: origin) else { continue }
            context.setPermissionStatus(.deniedExplicitly, for: pattern)
        }
        applyFileAccess(record.allowsFileAccess == true, to: context)
    }

    /// File pages are refused unless the person allowed them: a denied
    /// pattern outranks a granted one, `<all_urls>` included.
    private func applyFileAccess(_ allowed: Bool, to context: WKWebExtensionContext) {
        let pattern = SafariExtensionSettings.fileURLPattern
        guard let files = try? WKWebExtension.MatchPattern(string: pattern) else { return }
        context.setPermissionStatus(allowed ? .unknown : .deniedExplicitly, for: files)
    }

    /// Keeps `id`'s record in step with every grant and refusal WebKit
    /// reports, whoever made it: a prompt, the extension's own
    /// `permissions.remove`, an install.
    private func observePermissions(of context: WKWebExtensionContext, id: String) -> [NSObjectProtocol] {
        let names: [Notification.Name] = [
            WKWebExtensionContext.permissionsWereGrantedNotification,
            WKWebExtensionContext.permissionsWereDeniedNotification,
            WKWebExtensionContext.grantedPermissionsWereRemovedNotification,
            WKWebExtensionContext.deniedPermissionsWereRemovedNotification,
            WKWebExtensionContext.permissionMatchPatternsWereGrantedNotification,
            WKWebExtensionContext.permissionMatchPatternsWereDeniedNotification,
            WKWebExtensionContext.grantedPermissionMatchPatternsWereRemovedNotification,
            WKWebExtensionContext.deniedPermissionMatchPatternsWereRemovedNotification
        ]
        return names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: context, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.recordPermissions(of: id) }
            }
        }
    }

    private func recordPermissions(of id: String) {
        guard let entry = entry(id), let context = entry.context else { return }
        entry.record.grantedPermissions = context.grantedPermissions.keys.map(\.rawValue).sorted()
        entry.record.deniedPermissions = context.deniedPermissions.keys.map(\.rawValue).sorted()
        entry.record.grantedOrigins = context.grantedPermissionMatchPatterns.keys.map(\.string).sorted()
        entry.record.deniedOrigins = context.deniedPermissionMatchPatterns.keys.map(\.string).sorted()
        save()
    }

    private func entry(_ id: String) -> Entry? {
        entries.first { $0.record.id == id }
    }

    private func save() {
        guard libraryError == nil else { return }
        do {
            try library.save(entries.map(\.record))
        } catch {
            logger.error("extension records not saved: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func changed() {
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
        actionsChanged()
    }

    private func actionsChanged() {
        NotificationCenter.default.post(name: Self.actionsDidChangeNotification, object: self)
    }

    // MARK: - Install, update, remove

    /// Installs the extension `text` names (an ID or a Chrome Web Store
    /// link): downloads it, shows the person what it asks for, and turns it
    /// on once they agree. Installing one that is already installed updates
    /// it. Returns false when the person declined.
    public func install(_ text: String, presentingOn window: NSWindow?) async throws -> Bool {
        guard libraryError == nil else { throw Failure.library(libraryError ?? "") }
        guard let id = WebStoreExtension.id(from: text) else { throw WebStoreExtension.Failure.notAnExtension(text) }
        let crx = try await SafariExtensionLibrary.download(id: id)
        return try await install(crx: crx, id: id, presentingOn: window)
    }

    /// Copies the Safari extension `source` (one a Mac App Store app
    /// installed) into the library: shows the person what it asks for, and
    /// turns it on once they agree. Copying one that is already in the
    /// library refreshes it. Returns false when the person declined.
    public func installAppExtension(_ source: SafariAppExtension, presentingOn window: NSWindow?) async throws -> Bool {
        guard libraryError == nil else { throw Failure.library(libraryError ?? "") }
        let id = source.bundleID
        let staged = try library.stage(copyOf: source.resourcesURL, as: id)
        let appSource = SafariExtensionRecord.AppSource(source)
        let installed = try await installStaged(
            staged, id: id, presentingOn: window,
            newRecord: SafariExtensionRecord(id: id, isFromWebStore: false, appSource: appSource))
        if installed, let entry = entry(id) {
            entry.record.appSource = appSource
            entry.sourceMissing = false
            save()
            if entry.record.isEnabled, entry.context == nil {
                do { try start(entry) } catch { entry.failure = error.localizedDescription }
            }
            changed()
        }
        return installed
    }

    /// The Safari extensions installed on this Mac that are not in the
    /// library yet: what Add… offers.
    public func availableAppExtensions() async -> [SafariAppExtension] {
        (await SafariAppExtension.installed() ?? []).filter { !isInstalled($0.bundleID) }
    }

    /// Why the host refused.
    public enum Failure: Error, LocalizedError {
        case library(String)
        case notInstalled(String)
        /// A copied Safari extension's app is gone: the name is the app's.
        case appRemoved(String)

        public var errorDescription: String? {
            switch self {
            case .library(let detail): detail
            case .notInstalled(let id): "No extension \(id) is installed."
            case .appRemoved(let app):
                "\(app) is no longer installed. Install it again from the App Store to turn this extension on."
            }
        }
    }

    private func install(crx: Data, id: String, presentingOn window: NSWindow?) async throws -> Bool {
        let staged = try library.stage(crx, as: id)
        return try await installStaged(
            staged, id: id, presentingOn: window, newRecord: SafariExtensionRecord(id: id, isFromWebStore: true))
    }

    /// Installs the files staged at `staged` as `id`, asking the person first
    /// when it is new or asks for more than was granted. `newRecord` is the
    /// record a first install starts from.
    private func installStaged(
        _ staged: URL, id: String, presentingOn window: NSWindow?, newRecord: @autoclosure () -> SafariExtensionRecord
    ) async throws -> Bool {
        let existing = entry(id)
        do {
            let preview = try await WKWebExtension(resourceBaseURL: staged)
            let granted = Set(existing?.record.grantedPermissions ?? [])
            // Sites the last version asked for were answered already, by
            // the install or by the site access setting since.
            let answeredOrigins = Set(existing?.record.grantedOrigins ?? [])
                .union(existing?.webExtension?.allRequestedMatchPatterns.map(\.string) ?? [])
            let newPermissions = preview.requestedPermissions.map(\.rawValue).filter { !granted.contains($0) }.sorted()
            let newOrigins = preview.allRequestedMatchPatterns.map(\.string)
                .filter { !answeredOrigins.contains($0) }.sorted()
            if existing == nil || !newPermissions.isEmpty || !newOrigins.isEmpty {
                guard let window, await confirm(
                    preview, isUpdate: existing != nil, permissions: newPermissions, origins: newOrigins, on: window
                ) else {
                    library.discardStaged(id)
                    return false
                }
            }
        } catch {
            library.discardStaged(id)
            throw error
        }

        let entry = existing ?? Entry(record: newRecord())
        let wasEnabled = entry.record.isEnabled
        stop(entry)
        try library.commitStaged(id)
        let webExtension = try await WKWebExtension(resourceBaseURL: library.directory(of: id))
        entry.webExtension = webExtension
        entry.failure = nil
        // What the person just agreed to (or agreed to before) is granted.
        entry.record.grantedPermissions = Array(Set(entry.record.grantedPermissions)
            .union(webExtension.requestedPermissions.map(\.rawValue))).sorted()
        // Sites follow the site access setting: all of them only when that
        // is what it says.
        if entry.record.effectiveSiteAccess == .allSites {
            entry.record.grantedOrigins = Array(Set(entry.record.grantedOrigins)
                .union(webExtension.allRequestedMatchPatterns.map(\.string))).sorted()
        }
        entry.record.isEnabled = existing == nil ? true : wasEnabled
        if existing == nil { entries.append(entry) }
        save()
        if entry.record.isEnabled {
            do { try start(entry) } catch { entry.failure = error.localizedDescription }
        }
        changed()
        return true
    }

    /// The install sheet: what the extension is and what it may do.
    private func confirm(
        _ webExtension: WKWebExtension, isUpdate: Bool, permissions: [String], origins: [String], on window: NSWindow
    ) async -> Bool {
        let name = webExtension.displayName ?? "This extension"
        let alert = NSAlert()
        alert.messageText = isUpdate ? "“\(name)” asks for more access" : "Add “\(name)”?"
        var lines: [String] = []
        if let summary = webExtension.displayDescription, !summary.isEmpty { lines.append(summary) }
        if !permissions.isEmpty { lines.append("It can use: " + permissions.joined(separator: ", ") + ".") }
        if !origins.isEmpty {
            let shown = origins.prefix(8).joined(separator: ", ")
            let more = origins.count > 8 ? " and \(origins.count - 8) more" : ""
            lines.append("It can read and change pages on: \(shown)\(more).")
        }
        alert.informativeText = lines.joined(separator: "\n\n")
        alert.icon = webExtension.icon(for: CGSize(width: 64, height: 64))
        alert.addButton(withTitle: isUpdate ? "Update" : "Add Extension")
        alert.addButton(withTitle: "Cancel")
        return await withCheckedContinuation { continuation in
            alert.beginSheetModal(for: window) { response in
                continuation.resume(returning: response == .alertFirstButtonReturn)
            }
        }
    }

    /// Turns `id` on or off. Off unloads it from every page; its storage
    /// and answers stay.
    public func setEnabled(_ id: String, _ isEnabled: Bool) throws {
        guard let entry = entry(id) else { throw Failure.notInstalled(id) }
        if isEnabled, entry.sourceMissing, let source = entry.record.appSource {
            throw Failure.appRemoved(source.appName)
        }
        entry.record.isEnabled = isEnabled
        if isEnabled {
            if entry.webExtension == nil {
                Task { @MainActor in
                    await open(entry)
                    changed()
                }
            } else {
                try start(entry)
            }
        } else {
            stop(entry)
        }
        save()
        changed()
    }

    /// Removes `id`: unloads it, deletes the storage WebKit kept for it,
    /// its files and its record.
    public func remove(_ id: String) async throws {
        guard let entry = entry(id) else { throw Failure.notInstalled(id) }
        if let context = entry.context {
            let types = WKWebExtensionController.allExtensionDataTypes
            let record: WKWebExtension.DataRecord? = await withCheckedContinuation { continuation in
                controller.fetchDataRecord(ofTypes: types, for: context) { continuation.resume(returning: $0) }
            }
            if let record {
                await withCheckedContinuation { continuation in
                    controller.removeData(ofTypes: types, from: [record]) { continuation.resume() }
                }
            }
        }
        stop(entry)
        entries.removeAll { $0 === entry }
        try library.removeFiles(of: id)
        save()
        changed()
    }

    /// What `checkForUpdates` did.
    public struct UpdateReport: Sendable {
        public var updated: [String] = []
        /// An update that asks for more than was granted, held back because
        /// there was nowhere to ask: install it again to review it.
        public var heldBack: [String] = []
        public var failures: [String] = []
    }

    /// Asks the Chrome Web Store for a newer version of each extension
    /// installed from it, and installs what it offers; copies each Safari
    /// extension again whose app now carries a different version, and turns
    /// off the ones whose app is gone. An update that asks for more access
    /// is shown on `window`, or held back without one.
    @discardableResult
    public func checkForUpdates(presentingOn window: NSWindow?) async -> UpdateReport {
        var report = UpdateReport()
        await refreshCopies(presentingOn: window, into: &report)
        for entry in entries where entry.record.isFromWebStore {
            guard let webExtension = entry.webExtension else { continue }
            let id = entry.record.id
            let name = webExtension.displayName ?? id
            let installed = webExtension.version ?? webExtension.displayVersion ?? "0"
            do {
                let offered = try await SafariExtensionLibrary.offeredUpdate(id: id, installed: installed)
                guard offered != nil else { continue }
                let crx = try await SafariExtensionLibrary.download(id: id)
                if try await install(crx: crx, id: id, presentingOn: window) {
                    report.updated.append(name)
                } else {
                    report.heldBack.append(name)
                }
            } catch {
                report.failures.append("\(name): \(error.localizedDescription)")
            }
        }
        if !report.updated.isEmpty || !report.heldBack.isEmpty || !report.failures.isEmpty {
            let (updated, held, failed) = (report.updated.count, report.heldBack.count, report.failures.count)
            logger.info("update check: \(updated) updated, \(held) held back, \(failed) failed")
        }
        return report
    }

    /// Brings each copied Safari extension in step with its app, as the
    /// system's plug-in registry lists it now. Leaves them all as they are
    /// when the registry cannot be asked.
    private func refreshCopies(presentingOn window: NSWindow?, into report: inout UpdateReport) async {
        let copies = entries.filter { $0.record.appSource != nil }
        guard !copies.isEmpty, let installed = await SafariAppExtension.installed() else { return }
        for entry in copies {
            guard let source = entry.record.appSource, entries.contains(where: { $0 === entry }) else { continue }
            let id = entry.record.id
            let name = entry.webExtension?.displayName ?? id
            guard let current = installed.first(where: { $0.bundleID == id }) else {
                entry.sourceMissing = true
                stop(entry)
                continue
            }
            entry.sourceMissing = false
            if current.version != source.version {
                do {
                    if try await installAppExtension(current, presentingOn: window) {
                        report.updated.append(name)
                    } else {
                        report.heldBack.append(name)
                    }
                } catch {
                    report.failures.append("\(name): \(error.localizedDescription)")
                }
            } else if current.appexURL.path != source.appexPath || current.appName != source.appName {
                // The app moved or was renamed; the files are the same.
                entry.record.appSource = .init(current)
                save()
            }
            // An app that came back brings its extension back on.
            if entry.record.isEnabled, entry.context == nil, entry.webExtension != nil {
                do { try start(entry) } catch { entry.failure = error.localizedDescription }
            }
        }
        changed()
    }

    // MARK: - Details

    /// One extension as its details page shows it.
    public struct Details: Sendable {
        public var id: String
        public var name: String
        public var version: String
        public var summary: String
        public var iconPNG: Data?
        public var isEnabled: Bool
        /// Its app is gone, so it cannot be turned on.
        public var isSourceMissing: Bool
        public var isFromWebStore: Bool
        public var appSource: SafariExtensionRecord.AppSource?
        /// The permissions its manifest asks for, by Chrome's names.
        public var permissions: [String]
        /// The sites its manifest asks for, as match patterns.
        public var requestedOrigins: [String]
        public var siteAccess: SafariExtensionSiteAccess
        public var sites: [String]
        public var offersFileAccess: Bool
        public var allowsFileAccess: Bool
        public var allowsPrivateBrowsing: Bool
        public var isPinned: Bool
        public var optionsURL: URL?
        /// Where its files are.
        public var directory: URL
    }

    /// `id`'s details, or nil when it is not installed.
    public func details(of id: String) -> Details? {
        guard let entry = entry(id) else { return nil }
        let record = entry.record
        let webExtension = entry.webExtension
        let requested = webExtension?.allRequestedMatchPatterns.map(\.string).sorted() ?? []
        return Details(
            id: id,
            name: webExtension?.displayName ?? id,
            version: webExtension?.displayVersion ?? webExtension?.version ?? "",
            summary: entry.failure ?? webExtension?.displayDescription ?? "",
            iconPNG: Self.png(webExtension?.icon(for: CGSize(width: 64, height: 64))),
            isEnabled: record.isEnabled && !entry.sourceMissing,
            isSourceMissing: entry.sourceMissing,
            isFromWebStore: record.isFromWebStore,
            appSource: record.appSource,
            permissions: webExtension?.requestedPermissions.map(\.rawValue).sorted() ?? [],
            requestedOrigins: requested,
            siteAccess: record.effectiveSiteAccess,
            sites: record.sites ?? [],
            offersFileAccess: SafariExtensionSettings.offersFileAccess(requested: requested),
            allowsFileAccess: record.allowsFileAccess == true,
            allowsPrivateBrowsing: record.allowsPrivateBrowsing == true,
            isPinned: record.isPinned ?? true,
            optionsURL: entry.context?.optionsPageURL,
            directory: library.directory(of: id))
    }

    /// Which sites `id` may read and change. Specific sites are `sites`'
    /// match patterns; the other modes keep the list without using it.
    /// Takes effect on every open page at once.
    public func setSiteAccess(_ id: String, _ mode: SafariExtensionSiteAccess, sites: [String]? = nil) throws {
        guard let entry = entry(id) else { throw Failure.notInstalled(id) }
        if let sites { entry.record.sites = sites }
        entry.record.siteAccess = mode
        let requested = entry.webExtension?.allRequestedMatchPatterns.map(\.string) ?? []
        let origins = SafariExtensionSettings.grantedOrigins(
            for: mode, requested: requested, sites: entry.record.sites ?? [])
        if let context = entry.context {
            for pattern in context.grantedPermissionMatchPatterns.keys {
                context.setPermissionStatus(.unknown, for: pattern)
            }
            for origin in origins {
                guard let pattern = try? WKWebExtension.MatchPattern(string: origin) else { continue }
                context.setPermissionStatus(.grantedExplicitly, for: pattern)
            }
        }
        // Written here as well as by the observers, for an extension that is off.
        entry.record.grantedOrigins = origins
        save()
        changed()
    }

    /// Whether `id` may read the `file://` pages its sites cover.
    public func setFileAccess(_ id: String, _ allowed: Bool) throws {
        guard let entry = entry(id) else { throw Failure.notInstalled(id) }
        entry.record.allowsFileAccess = allowed
        if let context = entry.context { applyFileAccess(allowed, to: context) }
        entry.record.deniedOrigins.removeAll { $0 == SafariExtensionSettings.fileURLPattern }
        save()
        changed()
    }

    /// Whether `id` runs in private browsing panes.
    public func setPrivateAccess(_ id: String, _ allowed: Bool) throws {
        guard let entry = entry(id) else { throw Failure.notInstalled(id) }
        entry.record.allowsPrivateBrowsing = allowed
        entry.context?.hasAccessToPrivateData = allowed
        save()
        changed()
    }

    /// Whether `id`'s button is on the toolbar or in its extensions menu.
    public func setPinned(_ id: String, _ pinned: Bool) throws {
        guard let entry = entry(id) else { throw Failure.notInstalled(id) }
        entry.record.isPinned = pinned
        save()
        changed()
    }

    /// Whether `id`'s button is on the toolbar.
    public func isPinned(_ id: String) -> Bool {
        entry(id)?.record.isPinned ?? true
    }

    /// The bytes `id`'s files take on disk, counted off the main thread.
    public func diskSize(of id: String) async -> Int64 {
        let directory = library.directory(of: id)
        return await Task.detached(priority: .utility) {
            var total: Int64 = 0
            let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .isRegularFileKey]
            guard let walker = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: keys) else {
                return 0
            }
            while let url = walker.nextObject() as? URL {
                guard let values = try? url.resourceValues(forKeys: Set(keys)), values.isRegularFile == true else {
                    continue
                }
                total += Int64(values.totalFileAllocatedSize ?? 0)
            }
            return total
        }.value
    }

    // MARK: - Pages

    /// Runs the extension keyboard shortcut `event` is, if it is one.
    func performCommand(for event: NSEvent) -> Bool {
        loadedContexts.contains { $0.performCommand(for: event) }
    }

    /// The extensions' context-menu items for a page in `tab`.
    func menuItems(for tab: SafariExtensionTab) -> [NSMenuItem] {
        loadedContexts.flatMap { $0.menuItems(for: tab) }
    }

    // MARK: - Windows

    /// A pane's window adapter started (`didOpenWindow`) and its tabs with it.
    func register(_ window: SafariExtensionWindow) {
        guard !windows.contains(window) else { return }
        windows.add(window)
        controller.didOpenWindow(window)
        for tab in window.allTabs { controller.didOpenTab(tab) }
        if lastFocusedWindow == nil { noteFocus(window) }
    }

    /// A pane's window adapter is going away, its tabs with it.
    func unregister(_ window: SafariExtensionWindow) {
        guard windows.contains(window) else { return }
        for tab in window.allTabs { controller.didCloseTab(tab, windowIsClosing: true) }
        windows.remove(window)
        controller.didCloseWindow(window)
        if lastFocusedWindow === window { lastFocusedWindow = nil }
    }

    func noteFocus(_ window: SafariExtensionWindow) {
        guard windows.contains(window), lastFocusedWindow !== window else { return }
        lastFocusedWindow = window
        controller.didFocusWindow(window)
    }

    /// The pane in the key window when it is one of ours, else the last one
    /// focused.
    func focusedWindow() -> SafariExtensionWindow? {
        let all = windows.allObjects
        return all.first { $0.isInKeyWindow } ?? lastFocusedWindow ?? all.first
    }

    private static func png(_ image: NSImage?) -> Data? {
        guard let tiff = image?.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }

    fileprivate static func error(_ text: String) -> NSError {
        NSError(domain: "SafariExtensionHost", code: 1, userInfo: [NSLocalizedDescriptionKey: text])
    }
}

// MARK: - WKWebExtensionControllerDelegate

@available(macOS 15.4, *)
extension SafariExtensionHost: WKWebExtensionControllerDelegate {

    public func webExtensionController(
        _ controller: WKWebExtensionController, openWindowsFor extensionContext: WKWebExtensionContext
    ) -> [any WKWebExtensionWindow] {
        let visible = windows.allObjects.filter { $0.isVisible(to: extensionContext) }
        let focused = focusedWindow().flatMap { visible.contains($0) ? $0 : nil }
        let rest = visible.filter { $0 !== focused }
        return (focused.map { [$0] } ?? []) + rest
    }

    public func webExtensionController(
        _ controller: WKWebExtensionController, focusedWindowFor extensionContext: WKWebExtensionContext
    ) -> (any WKWebExtensionWindow)? {
        focusedWindow().flatMap { $0.isVisible(to: extensionContext) ? $0 : nil }
    }

    /// A pane has no windows of its own to open, so `windows.create` opens
    /// its pages as tabs in the window in front and answers with that.
    public func webExtensionController(
        _ controller: WKWebExtensionController,
        openNewWindowUsing configuration: WKWebExtension.WindowConfiguration,
        for extensionContext: WKWebExtensionContext,
        completionHandler: @escaping ((any WKWebExtensionWindow)?, (any Error)?) -> Void
    ) {
        guard let window = focusedWindow(), let pane = window.pane else {
            completionHandler(nil, Self.error("No Safari pane is open."))
            return
        }
        for (index, url) in configuration.tabURLs.enumerated() {
            pane.openTab(url, inBackground: index > 0 || !configuration.shouldBeFocused)
        }
        completionHandler(window, nil)
    }

    public func webExtensionController(
        _ controller: WKWebExtensionController,
        openNewTabUsing configuration: WKWebExtension.TabConfiguration,
        for extensionContext: WKWebExtensionContext,
        completionHandler: @escaping ((any WKWebExtensionTab)?, (any Error)?) -> Void
    ) {
        let window = (configuration.window as? SafariExtensionWindow) ?? focusedWindow()
        guard let window, let pane = window.pane,
              let engine = pane.openTab(configuration.url, inBackground: !configuration.shouldBeActive) else {
            completionHandler(nil, Self.error("No Safari pane is open."))
            return
        }
        completionHandler(window.tab(for: engine), nil)
    }

    public func webExtensionController(
        _ controller: WKWebExtensionController,
        openOptionsPageFor extensionContext: WKWebExtensionContext,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        guard let url = extensionContext.optionsPageURL else {
            completionHandler(Self.error("The extension has no options page."))
            return
        }
        guard let pane = focusedWindow()?.pane else {
            completionHandler(Self.error("No Safari pane is open."))
            return
        }
        pane.openTab(url, inBackground: false)
        completionHandler(nil)
    }

    /// `permissions.request`: the extension asks, the person answers.
    public func webExtensionController(
        _ controller: WKWebExtensionController,
        promptForPermissions permissions: Set<WKWebExtension.Permission>,
        in tab: (any WKWebExtensionTab)?,
        for extensionContext: WKWebExtensionContext,
        completionHandler: @escaping (Set<WKWebExtension.Permission>, Date?) -> Void
    ) {
        let names = permissions.map(\.rawValue).sorted()
        ask(extensionContext, toUse: "use " + names.joined(separator: ", "), in: tab) { allowed in
            completionHandler(allowed ? permissions : [], nil)
        }
    }

    public func webExtensionController(
        _ controller: WKWebExtensionController,
        promptForPermissionToAccess urls: Set<URL>,
        in tab: (any WKWebExtensionTab)?,
        for extensionContext: WKWebExtensionContext,
        completionHandler: @escaping (Set<URL>, Date?) -> Void
    ) {
        let hosts = Set(urls.compactMap(\.host)).sorted()
        let what = hosts.isEmpty ? "this page" : hosts.joined(separator: ", ")
        ask(extensionContext, toUse: "read and change \(what)", in: tab) { allowed in
            completionHandler(allowed ? urls : [], nil)
        }
    }

    public func webExtensionController(
        _ controller: WKWebExtensionController,
        promptForPermissionMatchPatterns matchPatterns: Set<WKWebExtension.MatchPattern>,
        in tab: (any WKWebExtensionTab)?,
        for extensionContext: WKWebExtensionContext,
        completionHandler: @escaping (Set<WKWebExtension.MatchPattern>, Date?) -> Void
    ) {
        let sites = matchPatterns.map(\.string).sorted().joined(separator: ", ")
        ask(extensionContext, toUse: "read and change pages on \(sites)", in: tab) { allowed in
            completionHandler(allowed ? matchPatterns : [], nil)
        }
    }

    public func webExtensionController(
        _ controller: WKWebExtensionController,
        didUpdate action: WKWebExtension.Action,
        forExtensionContext context: WKWebExtensionContext
    ) {
        actionsChanged()
    }

    public func webExtensionController(
        _ controller: WKWebExtensionController,
        presentActionPopup action: WKWebExtension.Action,
        for context: WKWebExtensionContext,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        guard let toolbar = focusedWindow()?.toolbar, toolbar.presentPopup(for: action) else {
            completionHandler(Self.error("There is no toolbar to show the popup from."))
            return
        }
        completionHandler(nil)
    }

    /// Native messaging talks to an app Chrome would have installed beside
    /// it; there is none here.
    public func webExtensionController(
        _ controller: WKWebExtensionController,
        sendMessage message: Any,
        toApplicationWithIdentifier applicationIdentifier: String?,
        for extensionContext: WKWebExtensionContext,
        replyHandler: @escaping (Any?, (any Error)?) -> Void
    ) {
        replyHandler(nil, Self.error("Native messaging is not supported."))
    }

    public func webExtensionController(
        _ controller: WKWebExtensionController,
        connectUsing port: WKWebExtension.MessagePort,
        for extensionContext: WKWebExtensionContext,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        completionHandler(Self.error("Native messaging is not supported."))
    }

    /// One permission question, as a sheet on the window the request came
    /// from (or the one in front); refused when there is no window to ask on.
    private func ask(
        _ context: WKWebExtensionContext, toUse what: String, in tab: (any WKWebExtensionTab)?,
        answer: @escaping (Bool) -> Void
    ) {
        let window = (tab as? SafariExtensionTab)?.window?.nsWindow ?? focusedWindow()?.nsWindow
        guard let window else {
            answer(false)
            return
        }
        let name = context.webExtension.displayName ?? "An extension"
        let alert = NSAlert()
        alert.messageText = "Allow “\(name)” to \(what)?"
        alert.icon = context.webExtension.icon(for: CGSize(width: 64, height: 64))
        alert.addButton(withTitle: "Allow")
        alert.addButton(withTitle: "Don’t Allow")
        alert.beginSheetModal(for: window) { response in
            answer(response == .alertFirstButtonReturn)
        }
    }
}
