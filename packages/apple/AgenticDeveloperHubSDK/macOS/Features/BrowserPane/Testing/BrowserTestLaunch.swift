//
//  BrowserTestLaunch.swift
//  AgenticDeveloperHubSDK
//
//  The web privacy test harness's way into the app
//  (docs/designs/web-privacy-test-harness.md in the Kitchen): the XCUITest
//  runner is sandboxed and cannot script the app, so it launches it with
//  `APP_TEST_BROWSER_URL` and `APP_TEST_BROWSER_SETTINGS`, and the app opens a
//  browser window on that page with those settings as per-window overrides.
//
//  Debug only: the whole file compiles out of a shipping binary, and the host
//  calls it only under a scratch test home, so it cannot reach a customer.
//

#if DEBUG
import AgenticDeveloperHubSDKCore
import Foundation

@MainActor
public enum BrowserTestLaunch {

    public nonisolated static let urlVariable = "APP_TEST_BROWSER_URL"
    public nonisolated static let settingsVariable = "APP_TEST_BROWSER_SETTINGS"

    public struct Request {
        public let url: URL
        /// Setting name → JSON scalar, every name a real browser key.
        public let overrides: [String: Any]
    }

    public enum LaunchError: Error, CustomStringConvertible {
        case badURL(String)
        case badSettingsJSON(String)
        case unknownSetting(String)
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

    /// Writes `overrides` into `store`, a window's own settings layer.
    public static func apply(_ overrides: [String: Any], to store: SettingsStore) throws {
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
        for (name, value) in request.overrides {
            do { try key(named: name).check(json: value) } catch let error as LaunchError {
                throw error
            } catch { throw LaunchError.badValue(name, error) }
        }
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
