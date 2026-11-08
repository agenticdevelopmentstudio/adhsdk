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

    func test_validation_choiceWithEmptyOptions_fails() throws {
        let field = DesktopAppSettingsSchema.Field(key: "k", label: "K", kind: .choice(default: "a", options: []))
        let app = StubApp(identifier: "a", schema: DesktopAppSettingsSchema(fields: [field]))
        let message = try XCTUnwrap(DesktopAppRegistry.validationFailure(for: app, in: []))
        XCTAssertTrue(message.contains("no options"), message)
    }

    func test_validation_choiceDefaultNotAmongOptions_fails() throws {
        let field = DesktopAppSettingsSchema.Field(
            key: "k", label: "K", kind: .choice(default: "z", options: [.init(id: "a", label: "A")])
        )
        let app = StubApp(identifier: "a", schema: DesktopAppSettingsSchema(fields: [field]))
        let message = try XCTUnwrap(DesktopAppRegistry.validationFailure(for: app, in: []))
        XCTAssertTrue(message.contains("not among its options"), message)
    }

    func test_validation_integerDefaultOutsideRange_fails() throws {
        let field = DesktopAppSettingsSchema.Field(key: "k", label: "K", kind: .integer(default: 99, range: 1...10))
        let app = StubApp(identifier: "a", schema: DesktopAppSettingsSchema(fields: [field]))
        let message = try XCTUnwrap(DesktopAppRegistry.validationFailure(for: app, in: []))
        XCTAssertTrue(message.contains("outside its range"), message)
    }

    func test_validation_validDefaults_pass() {
        let fields: [DesktopAppSettingsSchema.Field] = [
            .init(key: "i", label: "I", kind: .integer(default: 5, range: 1...10)),
            .init(key: "c", label: "C", kind: .choice(default: "a", options: [.init(id: "a", label: "A")]))
        ]
        let app = StubApp(identifier: "a", schema: DesktopAppSettingsSchema(fields: fields))
        XCTAssertNil(DesktopAppRegistry.validationFailure(for: app, in: []))
    }

    func test_validation_identifierThatIsDotPrefixOfAnother_fails_inEitherOrder() {
        let parent = StubApp(identifier: "a.b")
        let child = StubApp(identifier: "a.b.c")
        XCTAssertNotNil(DesktopAppRegistry.validationFailure(for: child, in: [parent]))
        XCTAssertNotNil(DesktopAppRegistry.validationFailure(for: parent, in: [child]))
        // A shared leading string that is not a whole dotted segment is fine.
        XCTAssertNil(DesktopAppRegistry.validationFailure(for: StubApp(identifier: "a.bc"), in: [parent]))
    }
}
