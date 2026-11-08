import AppKit
import XCTest
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKDesktop
@testable import AgenticDeveloperHubSDKDesktopApps

@MainActor
final class HelloWorldAppTests: XCTestCase {
    private func makeController(
        _ app: HelloWorldApp, _ context: FakeDesktopAppContext
    ) throws -> HelloWorldViewController {
        let controller = try XCTUnwrap(app.makeContentViewController(context: context) as? HelloWorldViewController)
        controller.loadViewIfNeeded()
        return controller
    }

    func test_helloWorld_descriptor_exactValues() {
        let descriptor = HelloWorldApp().descriptor
        XCTAssertEqual(descriptor.identifier, "com.agenticdeveloperhub.desktop.helloworld")
        XCTAssertEqual(descriptor.displayName, "Hello World")
        XCTAssertEqual(descriptor.version, "1.0")
        XCTAssertEqual(descriptor.summary, "The smallest possible Desktop app.")
        XCTAssertEqual(descriptor.icon, .symbol(name: "hand.wave.fill", tint: "#F28C28"))
        XCTAssertEqual(descriptor.attribution.author, "Agentic Developer Hub")
        XCTAssertEqual(descriptor.attribution.copyright, "© 2026 Agentic Developer Hub")
        XCTAssertNil(descriptor.attribution.url)
        XCTAssertNil(descriptor.integration)
        XCTAssertEqual(descriptor.defaultWindowSize, CGSize(width: 480, height: 320))
        XCTAssertEqual(descriptor.minimumWindowSize, CGSize(width: 320, height: 220))
        XCTAssertEqual(descriptor.settingsSchema.fields.map(\.key), ["greeting", "showTime"])
        XCTAssertEqual(descriptor.settingsSchema.fields.map(\.label), ["Greeting", "Show the time"])
        XCTAssertEqual(
            descriptor.settingsSchema.fields.map(\.kind),
            [.text(default: "Hello, World!", placeholder: nil), .toggle(default: true)])
    }

    func test_helloWorld_menus_containGreeting_withUppercaseAndReset() throws {
        let app = HelloWorldApp()
        let context = FakeDesktopAppContext(app: app)
        _ = try makeController(app, context)
        let menus = app.makeMenus(context: context)
        XCTAssertEqual(menus.map(\.title), ["Greeting"])
        let menu = try XCTUnwrap(menus.first)
        let uppercase = try XCTUnwrap(menu.item(named: "Uppercase"))
        XCTAssertEqual(uppercase.keyEquivalent, "u")
        XCTAssertEqual(uppercase.keyEquivalentModifierMask, .command)
        XCTAssertNotNil(menu.item(named: "Reset Greeting"))
    }

    func test_helloWorld_uppercase_togglesCheckmarkAndGreeting() throws {
        let app = HelloWorldApp()
        let context = FakeDesktopAppContext(app: app)
        let controller = try makeController(app, context)
        let uppercase = try XCTUnwrap(app.makeMenus(context: context).first?.item(named: "Uppercase"))
        let validator = try XCTUnwrap(uppercase.target as? ClosureMenuItemTarget)
        _ = validator.validateMenuItem(uppercase)
        XCTAssertEqual(uppercase.state, .off)
        XCTAssertEqual(controller.displayedGreeting, "Hello, World!")

        uppercase.fire()
        _ = validator.validateMenuItem(uppercase)
        XCTAssertEqual(uppercase.state, .on)
        XCTAssertEqual(controller.displayedGreeting, "HELLO, WORLD!")
    }

    func test_helloWorld_resetGreeting_restoresDefault() throws {
        let app = HelloWorldApp()
        let context = FakeDesktopAppContext(app: app)
        let controller = try makeController(app, context)
        context.settings.setString("Howdy", for: "greeting")
        XCTAssertEqual(controller.displayedGreeting, "Howdy")

        try XCTUnwrap(app.makeMenus(context: context).first?.item(named: "Reset Greeting")).fire()

        XCTAssertEqual(context.settings.string("greeting"), "Hello, World!")
        XCTAssertEqual(controller.displayedGreeting, "Hello, World!")
    }

    func test_helloWorld_showTime_hidesTimeLabelLive() throws {
        let app = HelloWorldApp()
        let context = FakeDesktopAppContext(app: app)
        let controller = try makeController(app, context)
        XCTAssertFalse(controller.isTimeHidden)
        context.settings.setBool(false, for: "showTime")
        XCTAssertTrue(controller.isTimeHidden)
    }

    func test_helloWorld_appWillClose_stopsTheClock() throws {
        let app = HelloWorldApp()
        let context = FakeDesktopAppContext(app: app)
        let controller = try makeController(app, context)
        XCTAssertTrue(controller.isClockRunning)
        app.appWillClose(context: context)
        XCTAssertFalse(controller.isClockRunning)
    }

    func test_helloWorld_clock_pausesWhenViewDisappears_andResumesWhenItAppears() throws {
        let app = HelloWorldApp()
        let context = FakeDesktopAppContext(app: app)
        let controller = try makeController(app, context)
        XCTAssertTrue(controller.isClockRunning)
        controller.viewDidDisappear()
        XCTAssertFalse(controller.isClockRunning)
        controller.viewWillAppear()
        XCTAssertTrue(controller.isClockRunning)
        controller.viewWillAppear()
        XCTAssertTrue(controller.isClockRunning)
        controller.stopClock()
    }
}
