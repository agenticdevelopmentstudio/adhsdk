import AppKit
import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDesktop

@MainActor
final class DesktopSettingsFormTests: XCTestCase {
    private let schema = DesktopAppSettingsSchema(fields: [
        .init(key: "on", label: "On", help: "Help text", kind: .toggle(default: false)),
        .init(key: "name", label: "Name", kind: .text(default: "x", placeholder: "Name")),
        .init(key: "count", label: "Count", kind: .integer(default: 5, range: 1...10)),
        .init(key: "mode", label: "Mode", kind: .choice(default: "a", options: [
            .init(id: "a", label: "A"), .init(id: "b", label: "B")
        ]))
    ])
    private var settings: DesktopAppSettings!
    private var form: DesktopSettingsFormViewController!

    override func setUp() async throws {
        try await super.setUp()
        settings = DesktopAppSettings(
            appIdentifier: "app",
            schema: schema,
            store: UserSettings(
                with: InMemorySettingsStorageProvider(),
                secureSettingsProvider: InMemorySecureSettingsStorageProvider()
            )
        )
        form = DesktopSettingsFormViewController(schema: schema, settings: settings)
        form.loadView()
    }

    private func all(_ view: NSView) -> [NSView] {
        view.subviews + view.subviews.flatMap { all($0) }
    }

    private func control<T: NSView>(_ type: T.Type, _ key: String) throws -> T {
        try XCTUnwrap(all(form.view).compactMap { $0 as? T }.first { $0.identifier?.rawValue == key })
    }

    func test_form_toggleWritesSetting() throws {
        let toggle = try control(NSSwitch.self, "on")
        XCTAssertEqual(toggle.state, .off)
        toggle.performClick(nil)
        XCTAssertTrue(settings.bool("on"))
    }

    func test_form_textWritesSetting() throws {
        let field = try control(NSTextField.self, "name")
        XCTAssertEqual(field.stringValue, "x")
        field.stringValue = "hello"
        _ = field.sendAction(field.action, to: field.target)
        XCTAssertEqual(settings.string("name"), "hello")
    }

    func test_form_integerClamps() throws {
        let field = try control(NSTextField.self, "count")
        let stepper = try control(NSStepper.self, "count")
        XCTAssertEqual(field.integerValue, 5)
        field.stringValue = "999"
        _ = field.sendAction(field.action, to: field.target)
        XCTAssertEqual(settings.integer("count"), 10)
        XCTAssertEqual(field.integerValue, 10)
        XCTAssertEqual(stepper.integerValue, 10)
        stepper.integerValue = 3
        _ = stepper.sendAction(stepper.action, to: stepper.target)
        XCTAssertEqual(settings.integer("count"), 3)
        XCTAssertEqual(field.integerValue, 3)
    }

    func test_form_choiceWritesSetting() throws {
        let popUp = try control(NSPopUpButton.self, "mode")
        XCTAssertEqual(popUp.titleOfSelectedItem, "A")
        popUp.selectItem(at: 1)
        _ = popUp.sendAction(popUp.action, to: popUp.target)
        XCTAssertEqual(settings.choice("mode"), "b")
    }

    func test_form_reflectsExternalChange() throws {
        settings.setBool(true, for: "on")
        XCTAssertEqual(try control(NSSwitch.self, "on").state, .on)
    }
}
