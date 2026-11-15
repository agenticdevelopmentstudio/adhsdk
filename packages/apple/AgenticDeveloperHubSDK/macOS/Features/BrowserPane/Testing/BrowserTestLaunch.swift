//
//  BrowserTestLaunch.swift
//  AgenticDeveloperHubSDK
//
//  A launch-time hook for UI tests of a host app's browser. An XCUITest runner
//  is sandboxed and cannot script the app it drives, so it launches the app
//  with `APP_TEST_BROWSER_URL` and `APP_TEST_BROWSER_SETTINGS` in its
//  environment, and the host hands that environment to `request(from:)` and
//  the result to `open(_:)`: a browser window on that page with those
//  settings as the window's own overrides.
//
//  Debug only: the whole file compiles out of a shipping binary. A host should
//  also call it only under a scratch test home, so a test's settings never
//  reach a real profile.
//

#if DEBUG
import AgenticDeveloperHubSDKCore
import Foundation

/// Opens a browser window described by a test runner's launch environment.
/// See the file header for how a host wires it in.
@MainActor
public enum BrowserTestLaunch {

    /// The environment variable holding the page to open, an absolute URL.
    public nonisolated static let urlVariable = "APP_TEST_BROWSER_URL"
    /// The environment variable holding the window's setting overrides: a
    /// JSON object of browser setting name to JSON scalar (a Bool, number or
    /// string, an enum's raw value). Optional.
    public nonisolated static let settingsVariable = "APP_TEST_BROWSER_SETTINGS"

    /// A validated launch request: a page, and the settings to open it with.
    public struct Request {
        /// The page the window opens on.
        public let url: URL
        /// Setting name → JSON scalar, every name a real browser key.
        public let overrides: [String: Any]

        /// A request built directly rather than from an environment. The
        /// names are not checked here; `open(_:)` checks every one, and every
        /// value, before it opens anything.
        public init(url: URL, overrides: [String: Any] = [:]) {
            self.url = url
            self.overrides = overrides
        }
    }

    /// Why a launch request was refused. Its `description` names the
    /// variable at fault, so a host can print it and exit.
    public enum LaunchError: Error, CustomStringConvertible {
        /// `urlVariable` is set but is not an absolute URL.
        case badURL(String)
        /// `settingsVariable` is set but is not a JSON object.
        case badSettingsJSON(String)
        /// An override names no browser setting.
        case unknownSetting(String)
        /// An override's value does not decode as its setting's type.
        case badValue(String, Error)

        public var description: String {
            switch self {
            case .badURL(let text): "\(BrowserTestLaunch.urlVariable) is not a URL: \(text)"
            case .badSettingsJSON(let text):
                "\(BrowserTestLaunch.settingsVariable) is not a JSON object: \(text)"
            case .unknownSetting(let name):
                "\(BrowserTestLaunch.settingsVariable) names no browser setting: \(name)"
            case .badValue(let name, let error):
                "\(BrowserTestLaunch.settingsVariable): bad value for \(name): \(error)"
            }
        }
    }

    /// The request `environment` carries, `nil` when it names no URL.
    /// Fails fast on anything malformed: a test that asked for a setting
    /// and silently ran without it would pass for the wrong reason.
    public static func request(from environment: [String: String]) throws -> Request? {
        guard let text = environment[urlVariable], !text.isEmpty else { return nil }
        guard let url = URL(string: text), url.scheme != nil else { throw LaunchError.badURL(text) }
        var overrides: [String: Any] = [:]
        if let json = environment[settingsVariable], !json.isEmpty {
            guard let object = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any] else {
                throw LaunchError.badSettingsJSON(json)
            }
            overrides = object
        }
        let known = Set(BrowserSettings.allKeyNames)
        if let unknown = overrides.keys.sorted().first(where: { !known.contains($0) }) {
            throw LaunchError.unknownSetting(unknown)
        }
        return Request(url: url, overrides: overrides)
    }

    /// Throws unless every override names a browser setting and decodes as
    /// that setting's type.
    static func check(_ overrides: [String: Any]) throws {
        for (name, value) in overrides {
            do { try key(named: name).check(json: value) } catch let error as LaunchError {
                throw error
            } catch { throw LaunchError.badValue(name, error) }
        }
    }

    /// Writes `overrides` into `store`, a window's own settings layer.
    static func apply(_ overrides: [String: Any], to store: SettingsStore) throws {
        for (name, value) in overrides {
            do { try key(named: name).set(json: value, in: store) } catch let error as LaunchError {
                throw error
            } catch { throw LaunchError.badValue(name, error) }
        }
    }

    /// Opens a browser window on the request's page with its overrides.
    /// Every value is checked before the window exists, so a bad one opens
    /// nothing rather than a window without the setting the test asked for.
    @discardableResult
    public static func open(_ request: Request) throws -> WebBrowserWindowController? {
        try check(request.overrides)
        return WebBrowserWindowController.openNew(url: request.url) { settings in
            try? apply(request.overrides, to: settings)
        }
    }

    private static func key(named name: String) throws -> any BrowserSettingKey {
        guard let key = BrowserSettings.allKeys.first(where: { $0.name == name }) else {
            throw LaunchError.unknownSetting(name)
        }
        return key
    }
}
#endif
