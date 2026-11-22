@testable import AgenticDeveloperHubSDKCore
import XCTest

/// `port-unique-across-instances`: a named instance may not declare an
/// `httpPort` another definition already holds.
final class StenographerInstancePortTests: XCTestCase {

    private var home: URL!

    override func setUpWithError() throws {
        home = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("instance-home-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: StenographerInstance.definitionsDirectory(home: home), withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: home)
    }

    /// A short data root outside `home`, so the socket path stays under the limit.
    private func dataRoot(_ name: String) -> String {
        "/tmp/sti-\(name)-\(UUID().uuidString.prefix(8))"
    }

    private func write(_ definition: StenographerInstance.Definition) throws {
        let file = StenographerInstance.definitionsDirectory(home: home)
            .appendingPathComponent("\(definition.name).json")
        try JSONEncoder().encode(definition).write(to: file)
    }

    func testAPortAnotherDefinitionHoldsIsRefused() throws {
        try write(.init(name: "alpha", dataRoot: dataRoot("alpha"), httpPort: 22950))
        let beta = StenographerInstance.Definition(name: "beta", dataRoot: dataRoot("beta"), httpPort: 22950)

        XCTAssertThrowsError(try StenographerInstance.validate(beta, fileName: "beta", home: home)) { error in
            XCTAssertEqual(error as? StenographerInstance.ResolutionError,
                           .portTakenByAnotherInstance(port: 22950, instance: "alpha"))
        }
    }

    func testResolvingADefinitionWhosePortIsTakenFails() throws {
        try write(.init(name: "alpha", dataRoot: dataRoot("alpha"), httpPort: 22951))
        try write(.init(name: "beta", dataRoot: dataRoot("beta"), httpPort: 22951))

        XCTAssertThrowsError(try StenographerInstance.resolve(name: "beta", home: home)) { error in
            XCTAssertEqual(error as? StenographerInstance.ResolutionError,
                           .portTakenByAnotherInstance(port: 22951, instance: "alpha"))
        }
    }

    func testDistinctPortsAreAccepted() throws {
        try write(.init(name: "alpha", dataRoot: dataRoot("alpha"), httpPort: 22952))
        let beta = StenographerInstance.Definition(name: "beta", dataRoot: dataRoot("beta"), httpPort: 22953)

        XCTAssertNoThrow(try StenographerInstance.validate(beta, fileName: "beta", home: home))
    }

    func testADefinitionDoesNotCollideWithItsOwnFile() throws {
        let alpha = StenographerInstance.Definition(name: "alpha", dataRoot: dataRoot("alpha"), httpPort: 22954)
        try write(alpha)

        XCTAssertEqual(try StenographerInstance.resolve(name: "alpha", home: home).httpPort, 22954)
    }

    /// The default instance has no HTTP port: 22847 was the retired
    /// stenographerd's, and nothing in the default instance uses it now.
    func testTheDefaultInstanceHasNoHTTPPort() {
        XCTAssertNil(StenographerInstance.default.httpPort)
    }

    /// 22847 is free for a named instance; the router's and adkd's are not.
    func testTheRetiredStenographerdPortIsFreeButTheReservedOnesAreNot() throws {
        XCTAssertEqual(StenographerInstance.reservedHTTPPorts, [22848, 22849])
        let dev = StenographerInstance.Definition(name: "dev", dataRoot: dataRoot("dev"), httpPort: 22847)
        XCTAssertNoThrow(try StenographerInstance.validate(dev, fileName: "dev", home: home))
        for port in [22848, 22849] {
            let taken = StenographerInstance.Definition(name: "dev", dataRoot: dataRoot("dev"), httpPort: port)
            XCTAssertThrowsError(try StenographerInstance.validate(taken, fileName: "dev", home: home)) { error in
                XCTAssertEqual(error as? StenographerInstance.ResolutionError, .invalidPort(port))
            }
        }
    }
}
