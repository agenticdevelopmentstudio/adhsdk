import XCTest
@testable import AgenticDeveloperHubSDKDesktop

@MainActor
final class DesktopAppRegistryTests: XCTestCase {
    func test_validation_duplicateIdentifier_fails() {
        let first = StubApp(identifier: "a")
        let second = StubApp(identifier: "a")
        XCTAssertNotNil(DesktopAppRegistry.validationFailure(for: second, in: [first]))
        XCTAssertNil(DesktopAppRegistry.validationFailure(for: StubApp(identifier: "b"), in: [first]))
    }

    func test_validation_duplicateSchemaKeys_fails() {
        let field = DesktopAppSettingsSchema.Field(key: "k", label: "K", kind: .toggle(default: false))
        let app = StubApp(identifier: "a", schema: DesktopAppSettingsSchema(fields: [field, field]))
        XCTAssertNotNil(DesktopAppRegistry.validationFailure(for: app, in: []))
    }

    func test_register_preservesOrder_and_lookupByIdentifier() {
        let registry = DesktopAppRegistry()
        let one = StubApp(identifier: "one")
        let two = StubApp(identifier: "two")
        registry.register(two)
        registry.register(one)
        XCTAssertEqual(registry.apps.map(\.descriptor.identifier), ["two", "one"])
        XCTAssertTrue(registry.app(withIdentifier: "one") === one)
        XCTAssertNil(registry.app(withIdentifier: "missing"))
    }
}
