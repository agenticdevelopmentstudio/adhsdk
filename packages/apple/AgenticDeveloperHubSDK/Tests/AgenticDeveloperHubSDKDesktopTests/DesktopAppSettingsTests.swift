import Combine
import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDesktop

@MainActor
final class DesktopAppSettingsTests: XCTestCase {
    private let appID = "com.x.app"
    private var store: UserSettings!
    private var cancellables = Set<AnyCancellable>()

    private var schema: DesktopAppSettingsSchema {
        DesktopAppSettingsSchema(fields: [
            .init(key: "greeting", label: "Greeting", kind: .text(default: "Hello", placeholder: nil)),
            .init(key: "loud", label: "Loud", kind: .toggle(default: false)),
            .init(key: "count", label: "Count", kind: .integer(default: 5, range: 1...10)),
            .init(key: "badDefault", label: "Bad", kind: .integer(default: 99, range: 1...10)),
            .init(key: "mode", label: "Mode", kind: .choice(default: "a", options: [
                .init(id: "a", label: "A"), .init(id: "b", label: "B")
            ]))
        ])
    }

    private func makeSettings() -> DesktopAppSettings {
        DesktopAppSettings(appIdentifier: appID, schema: schema, store: store)
    }

    override func setUp() async throws {
        try await super.setUp()
        store = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
    }

    func test_storageKey_isNamespaced() {
        XCTAssertEqual(
            DesktopAppSettings.storageKey(appIdentifier: "com.x.app", fieldKey: "greeting"),
            "desktopApp.com.x.app.greeting"
        )
    }

    func test_defaults_comeFromSchema() {
        let settings = makeSettings()
        XCTAssertEqual(settings.string("greeting"), "Hello")
        XCTAssertFalse(settings.bool("loud"))
        XCTAssertEqual(settings.integer("count"), 5)
        XCTAssertEqual(settings.choice("mode"), "a")
    }

    func test_set_then_read_roundTrips_eachKind() {
        let settings = makeSettings()
        settings.setString("Hi", for: "greeting")
        settings.setBool(true, for: "loud")
        settings.setInteger(7, for: "count")
        settings.setChoice("b", for: "mode")
        XCTAssertEqual(settings.string("greeting"), "Hi")
        XCTAssertTrue(settings.bool("loud"))
        XCTAssertEqual(settings.integer("count"), 7)
        XCTAssertEqual(settings.choice("mode"), "b")
    }

    func test_integer_clampsToRange() {
        let settings = makeSettings()
        settings.setInteger(500, for: "count")
        XCTAssertEqual(settings.integer("count"), 10)
        settings.setInteger(-3, for: "count")
        XCTAssertEqual(settings.integer("count"), 1)
    }

    func test_integer_defaultOutsideRange_readsClamped() {
        XCTAssertEqual(makeSettings().integer("badDefault"), 10)
    }

    func test_reset_restoresDefault() {
        let settings = makeSettings()
        settings.setString("Hi", for: "greeting")
        settings.setInteger(7, for: "count")
        settings.reset("greeting")
        settings.reset("count")
        XCTAssertEqual(settings.string("greeting"), "Hello")
        XCTAssertEqual(settings.integer("count"), 5)
    }

    func test_changes_emitsFieldKey() {
        let settings = makeSettings()
        var keys: [String] = []
        settings.changes.sink { keys.append($0) }.store(in: &cancellables)
        settings.setBool(true, for: "loud")
        XCTAssertEqual(keys, ["loud"])
    }

    func test_changes_ignoresOtherApps() {
        let settings = makeSettings()
        let other = DesktopAppSettings(appIdentifier: "com.y.app", schema: schema, store: store)
        var keys: [String] = []
        settings.changes.sink { keys.append($0) }.store(in: &cancellables)
        other.setBool(true, for: "loud")
        XCTAssertTrue(keys.isEmpty)
    }

    func test_kindMismatch_reportsUndeclaredKey() {
        XCTAssertNotNil(DesktopAppSettings.kindMismatch(key: "nope", access: .bool, schema: schema))
        XCTAssertNotNil(DesktopAppSettings.kindMismatch(key: "loud", access: .string, schema: schema))
        XCTAssertNil(DesktopAppSettings.kindMismatch(key: "loud", access: .bool, schema: schema))
    }

    func test_choice_staleStoredValue_readsAsDefault() {
        let settings = makeSettings()
        settings.setChoice("b", for: "mode")
        XCTAssertEqual(settings.choice("mode"), "b")
        // An option removed from the schema since the value was stored.
        let narrowed = DesktopAppSettingsSchema(fields: [
            .init(key: "mode", label: "Mode", kind: .choice(default: "a", options: [.init(id: "a", label: "A")]))
        ])
        let later = DesktopAppSettings(appIdentifier: appID, schema: narrowed, store: store)
        XCTAssertEqual(later.choice("mode"), "a")
    }

    func test_reset_removesEveryKindOfField() {
        let settings = makeSettings()
        settings.setString("Hi", for: "greeting")
        settings.setBool(true, for: "loud")
        settings.setInteger(7, for: "count")
        settings.setChoice("b", for: "mode")
        for key in ["greeting", "loud", "count", "mode"] { settings.reset(key) }
        XCTAssertEqual(store.keys(withPrefix: "desktopApp.\(appID)."), [])
        XCTAssertEqual(settings.string("greeting"), "Hello")
        XCTAssertEqual(settings.integer("count"), 5)
    }
}
