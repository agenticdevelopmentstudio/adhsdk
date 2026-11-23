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

    private func setCreated(_ name: String, _ date: Date) throws {
        let file = StenographerInstance.definitionsDirectory(home: home).appendingPathComponent("\(name).json")
        try FileManager.default.setAttributes([.creationDate: date], ofItemAtPath: file.path)
    }

    /// A newer definition that takes an existing one's port is the only one
    /// refused: the one that was there first keeps resolving.
    func testTheEarlierDefinitionKeepsItsPort() throws {
        try write(.init(name: "home", dataRoot: dataRoot("home"), httpPort: 22960))
        try write(.init(name: "lab", dataRoot: dataRoot("lab"), httpPort: 22960))
        try setCreated("home", Date(timeIntervalSince1970: 1_700_000_000))
        try setCreated("lab", Date(timeIntervalSince1970: 1_700_000_600))

        XCTAssertEqual(try StenographerInstance.resolve(name: "home", home: home).httpPort, 22960)
        XCTAssertThrowsError(try StenographerInstance.resolve(name: "lab", home: home)) { error in
            XCTAssertEqual(error as? StenographerInstance.ResolutionError,
                           .portTakenByAnotherInstance(port: 22960, instance: "home"))
        }
    }

    /// Precedence is by creation, not by name: a newer `alpha` loses to an
    /// older `zulu`.
    func testPrecedenceFollowsCreationNotName() throws {
        try write(.init(name: "zulu", dataRoot: dataRoot("zulu"), httpPort: 22961))
        try write(.init(name: "alpha", dataRoot: dataRoot("alpha"), httpPort: 22961))
        try setCreated("zulu", Date(timeIntervalSince1970: 1_700_000_000))
        try setCreated("alpha", Date(timeIntervalSince1970: 1_700_000_600))

        XCTAssertNoThrow(try StenographerInstance.resolve(name: "zulu", home: home))
        XCTAssertThrowsError(try StenographerInstance.resolve(name: "alpha", home: home)) { error in
            XCTAssertEqual(error as? StenographerInstance.ResolutionError,
                           .portTakenByAnotherInstance(port: 22961, instance: "zulu"))
        }
    }

    /// The same holds for a shared data root: the older instance resolves.
    func testTheEarlierDefinitionKeepsItsDataRoot() throws {
        let root = dataRoot("shared")
        try write(.init(name: "home", dataRoot: root, httpPort: 22962))
        try write(.init(name: "lab", dataRoot: root, httpPort: 22963))
        try setCreated("home", Date(timeIntervalSince1970: 1_700_000_000))
        try setCreated("lab", Date(timeIntervalSince1970: 1_700_000_600))

        XCTAssertNoThrow(try StenographerInstance.resolve(name: "home", home: home))
        XCTAssertThrowsError(try StenographerInstance.resolve(name: "lab", home: home)) { error in
            guard case .overlapsAnotherInstance(_, let instance, _)? = error as? StenographerInstance.ResolutionError
            else { return XCTFail("expected overlapsAnotherInstance, got \(error)") }
            XCTAssertEqual(instance, "home")
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

    /// 22847 is free for a named instance; the router's, adkd's and adhd's
    /// (release and dev) are not.
    func testTheRetiredStenographerdPortIsFreeButTheReservedOnesAreNot() throws {
        XCTAssertEqual(StenographerInstance.reservedHTTPPorts, [22848, 22849, 22850, 22871])
        let dev = StenographerInstance.Definition(name: "dev", dataRoot: dataRoot("dev"), httpPort: 22847)
        XCTAssertNoThrow(try StenographerInstance.validate(dev, fileName: "dev", home: home))
        for port in [22848, 22849, 22850, 22871] {
            let taken = StenographerInstance.Definition(name: "dev", dataRoot: dataRoot("dev"), httpPort: port)
            XCTAssertThrowsError(try StenographerInstance.validate(taken, fileName: "dev", home: home)) { error in
                XCTAssertEqual(error as? StenographerInstance.ResolutionError, .invalidPort(port))
            }
        }
    }

    /// Every well-known daemon port is reserved: adhd's release port
    /// (`DaemonContract.port`) and dev port (`DaemonIdentity.devPort`).
    func testEveryWellKnownDaemonPortIsReserved() {
        XCTAssertEqual(StenographerInstance.adhdHTTPPorts, [22850, 22871])
        XCTAssertTrue(StenographerInstance.adhdHTTPPorts.isSubset(of: StenographerInstance.reservedHTTPPorts))
        XCTAssertTrue(StenographerInstance.reservedHTTPPorts.contains(StenographerIdentifiers.routerPort))
    }
}
