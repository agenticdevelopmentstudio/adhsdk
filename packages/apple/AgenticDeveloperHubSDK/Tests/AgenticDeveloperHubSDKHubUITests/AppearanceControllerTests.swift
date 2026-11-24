import AgenticDeveloperHubClient
import XCTest
import AgenticDeveloperHubSDKHubService
@testable import AgenticDeveloperHubSDKHubAuth
@testable import AgenticDeveloperHubSDKHubUI

@MainActor
final class AppearanceControllerTests: XCTestCase {
    private static func account(appearance: String) -> String {
        #"""
        {"object":"account","id":"u1","email":"a@b.c","name":"Ada","avatar_url":"","slug":"ada",
        "public_profile_enabled":false,"profile_visibility":"public","capabilities":[],
        "appearance":{"prefs":\#(appearance)}}
        """#
    }

    private func make() -> (AppearanceController, StubClientTransport) {
        let stub = StubClientTransport()
        let environment = HubEnvironment(
            sessionStore: InMemorySessionStore(
                HubSession(credentials: Credentials(token: "jwt", kind: .jwt), refreshToken: "r")
            ),
            transportSource: StaticTransportSource(.direct(transport: stub)),
            initialTransport: .direct(transport: stub)
        )
        return (AppearanceController(environment: environment), stub)
    }

    func testRefreshAppliesTheServerColorMode() async {
        let (controller, stub) = make()
        let prefs = #"{"color_mode":"dark","reduce_motion":"auto"}"#
        stub.on(.get, "/v1/account", status: 200, json: Self.account(appearance: prefs))
        var seen: [HubColorMode] = []
        controller.onChange = { seen.append($0) }
        await controller.refresh()
        XCTAssertEqual(controller.colorMode, .dark)
        XCTAssertEqual(seen, [.dark])
    }

    func testEmptyPrefsMeanAuto() async {
        let (controller, stub) = make()
        stub.on(.get, "/v1/account", status: 200, json: Self.account(appearance: #"{"color_mode":"dark"}"#))
        await controller.refresh()
        XCTAssertEqual(controller.colorMode, .dark)
        stub.on(.get, "/v1/account", status: 200, json: Self.account(appearance: "{}"))
        await controller.refresh()
        XCTAssertEqual(controller.colorMode, .auto)
    }

    func testFailuresKeepTheCurrentMode() async {
        let (controller, stub) = make()
        stub.on(.get, "/v1/account", status: 200, json: Self.account(appearance: #"{"color_mode":"light"}"#))
        await controller.refresh()
        XCTAssertEqual(controller.colorMode, .light)
        stub.on(.get, "/v1/account", status: 401, json: StubClientTransport.error("nope"))
        await controller.refresh()
        XCTAssertEqual(controller.colorMode, .light)
        stub.on(.get, "/v1/account") { _, _ in throw URLError(.notConnectedToInternet) }
        await controller.refresh()
        XCTAssertEqual(controller.colorMode, .light)
        controller.reset()
        XCTAssertEqual(controller.colorMode, .auto)
    }

    func testModeMapping() {
        var settings = Components.Schemas.AppearanceSettings(prefs: .init())
        XCTAssertEqual(AppearanceController.mode(from: settings), .auto)
        settings.prefs.colorMode = .light
        XCTAssertEqual(AppearanceController.mode(from: settings), .light)
        settings.prefs.colorMode = .dark
        XCTAssertEqual(AppearanceController.mode(from: settings), .dark)
    }
}
