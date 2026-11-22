import Foundation

// MARK: - Router pointer

/// The `env.ANTHROPIC_BASE_URL` in `settings.json` that sends Claude Code's API
/// traffic through an account router. The router's URL is an argument
/// (`routerBaseURL`, Stenographer's port by default), so whichever daemon hosts
/// the router points Claude Code at its own port. Every write goes
/// through the toolkit installer's locked `modifySettings`, so it never races
/// a hook install or another tool holding the settings lock.
extension ClaudeHookInstaller {

    /// Present while ``suspendRouterPointer()`` has taken our pointer out, so
    /// ``resumeRouterPointer()`` knows to put it back. Beside the other markers.
    /// Named after the configuration (`.stenographer-router-pointer-suspended`
    /// for Stenographer's), so two installers never share a suspension.
    public var routerPointerSuspendedMarkerURL: URL {
        settingsURL.deletingLastPathComponent()
            .appendingPathComponent(".\(configuration.name)-router-pointer-suspended")
    }

    /// The `env` key in `settings.json` that sends Claude Code's API traffic
    /// through the account router.
    public static let routerBaseURLEnvKey = "ANTHROPIC_BASE_URL"

    /// What `env.ANTHROPIC_BASE_URL` in `settings.json` says.
    public enum RouterPointer: Equatable, Sendable {
        /// No `env.ANTHROPIC_BASE_URL`.
        case absent
        /// Exactly the router's base URL.
        case ours
        /// Anything else, in display form only: `scheme://host[:port]`, with any
        /// path, query, fragment and userinfo dropped (a URL can carry
        /// credentials), or "custom value" when it does not parse as a URL.
        case other(String)
    }

    /// Where Claude Code's API traffic goes, read without the settings lock. A
    /// missing, empty or unreadable `settings.json` reads `.absent`.
    public func routerPointer(routerBaseURL: String = StenographerIdentifiers.routerBaseURL) -> RouterPointer {
        guard let data = try? Data(contentsOf: settingsURL), !data.isEmpty,
              let settings = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return .absent
        }
        return Self.routerPointer(in: settings, routerBaseURL: routerBaseURL)
    }

    /// Points Claude Code at the account router (`enabled`) or stops pointing it
    /// there, under the settings lock, and returns the state afterwards. Every
    /// other key in `settings.json` is kept. A value that is not ours is never
    /// overwritten or removed: turning on throws `routerPointerConflict` with
    /// its display form, turning off leaves it and returns `.other`. An `env`
    /// that is not a JSON object counts as such a value. Nothing is written
    /// when nothing changes.
    @discardableResult
    public func setRouterPointer(
        _ enabled: Bool, routerBaseURL: String = StenographerIdentifiers.routerBaseURL
    ) throws -> RouterPointer {
        let marker = routerPointerSuspendedMarkerURL
        var changed = false
        let result: RouterPointer = try modifySettings { settings in
            // The user's own choice replaces a suspension: nothing is put back later.
            try? FileManager.default.removeItem(at: marker)
            let current = Self.routerPointer(in: settings, routerBaseURL: routerBaseURL)
            switch (enabled, current) {
            case (true, .ours), (false, .absent), (false, .other):
                return current
            case (true, .other(let display)):
                throw RouterPointerError.routerPointerConflict(display)
            case (true, .absent):
                settings = Self.settingsAddingRouterPointer(settings, routerBaseURL: routerBaseURL)
                changed = true
                return .ours
            case (false, .ours):
                settings = Self.settingsRemovingRouterPointer(settings)
                changed = true
                return .absent
            }
        }
        if changed && enabled {
            Self.logger.info("Pointed Claude Code at the account router")
        } else if changed {
            Self.logger.info("Claude Code no longer points at the account router")
        }
        return result
    }

    /// Takes our pointer out of `settings.json` while nothing will answer on
    /// the router's port (the daemon was stopped on purpose, or gave up after a
    /// crash loop), so Claude Code goes straight to Anthropic instead of failing
    /// every request. It records the suspension; ``resumeRouterPointer()`` puts
    /// the pointer back when the daemon starts. A value that is not ours is left
    /// alone. True when the pointer was taken out.
    @discardableResult
    public func suspendRouterPointer(routerBaseURL: String = StenographerIdentifiers.routerBaseURL) -> Bool {
        let marker = routerPointerSuspendedMarkerURL
        do {
            let suspended = try modifySettings { settings -> Bool in
                guard Self.routerPointer(in: settings, routerBaseURL: routerBaseURL) == .ours else { return false }
                // The marker first: a failed save leaves the pointer, and the
                // next resume finds it there and only drops the marker.
                try Data().write(to: marker, options: .atomic)
                settings = Self.settingsRemovingRouterPointer(settings)
                return true
            }
            if suspended { Self.logger.info("Router pointer suspended while the daemon is down") }
            return suspended
        } catch {
            Self.logger.error("Could not suspend the router pointer: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// Puts back a pointer ``suspendRouterPointer()`` took out, unless
    /// `ANTHROPIC_BASE_URL` was set to something else meanwhile. True when the
    /// pointer was put back. Without the marker nothing is read or written.
    @discardableResult
    public func resumeRouterPointer(routerBaseURL: String = StenographerIdentifiers.routerBaseURL) -> Bool {
        let marker = routerPointerSuspendedMarkerURL
        guard FileManager.default.fileExists(atPath: marker.path) else { return false }
        do {
            let restored = try modifySettings { settings -> Bool in
                guard FileManager.default.fileExists(atPath: marker.path) else { return false }
                guard Self.routerPointer(in: settings, routerBaseURL: routerBaseURL) == .absent else { return false }
                settings = Self.settingsAddingRouterPointer(settings, routerBaseURL: routerBaseURL)
                return true
            }
            // After the save: a failed save keeps the marker for the next start.
            try? FileManager.default.removeItem(at: marker)
            if restored { Self.logger.info("Router pointer restored") }
            return restored
        } catch {
            Self.logger.error("Could not restore the router pointer: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// Removes our hooks and status-line slot. `removingRouterPointer` also
    /// removes our `env.ANTHROPIC_BASE_URL` and forgets a suspension; only
    /// removing Stenographer passes it. Turning tracking off keeps the pointer:
    /// the router does not depend on tracking, and Claude Code would silently
    /// stop going through it. True when anything was removed.
    @discardableResult
    public func uninstallHooks(
        removingRouterPointer: Bool, routerBaseURL: String = StenographerIdentifiers.routerBaseURL
    ) -> Bool {
        let removedHooks = uninstallHooks()
        guard removingRouterPointer else { return removedHooks }
        try? FileManager.default.removeItem(at: routerPointerSuspendedMarkerURL)
        do {
            // Only our own router pointer; another ANTHROPIC_BASE_URL stays.
            let removedPointer = try modifySettings { settings -> Bool in
                guard Self.routerPointer(in: settings, routerBaseURL: routerBaseURL) == .ours else { return false }
                settings = Self.settingsRemovingRouterPointer(settings)
                return true
            }
            if removedPointer { Self.logger.info("Claude Code no longer points at the account router") }
            return removedHooks || removedPointer
        } catch {
            Self.logger.error("Router pointer removal failed: \(error.localizedDescription, privacy: .public)")
            return removedHooks
        }
    }

    public static func routerPointer(
        in settings: [String: Any], routerBaseURL: String = StenographerIdentifiers.routerBaseURL
    ) -> RouterPointer {
        guard let rawEnv = settings["env"] else { return .absent }
        guard let env = rawEnv as? [String: Any] else { return .other("env is not an object") }
        guard let value = env[routerBaseURLEnvKey] else { return .absent }
        if let string = value as? String, string == routerBaseURL { return .ours }
        return .other(routerPointerDisplay(value))
    }

    /// `scheme://host[:port]` of `value`, never its path, query, fragment or
    /// userinfo; "custom value" when it has no scheme and host.
    public static func routerPointerDisplay(_ value: Any) -> String {
        let custom = "custom value"
        guard let string = value as? String,
              let components = URLComponents(string: string.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = components.scheme, !scheme.isEmpty,
              let host = components.host, !host.isEmpty else { return custom }
        let shownHost = host.contains(":") && !host.hasPrefix("[") ? "[\(host)]" : host
        let port = components.port.map { ":\($0)" } ?? ""
        return "\(scheme.lowercased())://\(shownHost)\(port)"
    }

    /// `settings` with our `env.ANTHROPIC_BASE_URL`. Only call it when the
    /// pointer is `.absent`.
    private static func settingsAddingRouterPointer(
        _ settings: [String: Any], routerBaseURL: String
    ) -> [String: Any] {
        var settings = settings
        var env = settings["env"] as? [String: Any] ?? [:]
        env[routerBaseURLEnvKey] = routerBaseURL
        settings["env"] = env
        return settings
    }

    /// `settings` without our `env.ANTHROPIC_BASE_URL`, and without `env` when
    /// that empties it. Only call it when the pointer is `.ours`.
    private static func settingsRemovingRouterPointer(_ settings: [String: Any]) -> [String: Any] {
        var settings = settings
        var env = settings["env"] as? [String: Any] ?? [:]
        env[routerBaseURLEnvKey] = nil
        settings["env"] = env.isEmpty ? nil : env
        return settings
    }
}

/// A router-pointer write that was refused.
public enum RouterPointerError: Error, LocalizedError, Equatable {
    /// `env.ANTHROPIC_BASE_URL` already holds a value that is not ours; the
    /// payload is its display form (`ClaudeHookInstaller.RouterPointer.other`).
    case routerPointerConflict(String)

    public var errorDescription: String? {
        switch self {
        case .routerPointerConflict(let display):
            "ANTHROPIC_BASE_URL in ~/.claude/settings.json is already set (\(display)), "
                + "so it was left alone."
        }
    }
}
