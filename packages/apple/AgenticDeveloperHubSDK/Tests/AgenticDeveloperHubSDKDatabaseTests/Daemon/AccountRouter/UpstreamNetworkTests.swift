import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// The router reaches upstream through the proxy and extra CA certificates
/// Claude Code would have used, so turning routing on never breaks a network
/// that only works through them.
final class UpstreamNetworkTests: XCTestCase {
    private var tmpDir: URL!

    override func setUpWithError() throws {
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("sten-upstream-network-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    /// A self-signed test certificate; its key was never kept.
    private static let pem = """
        -----BEGIN CERTIFICATE-----
        MIICJDCCAcoCCQDXckBUAHRQRDAKBggqhkjOPQQDAjAfMR0wGwYDVQQDDBRTdGVu
        b2dyYXBoZXIgVGVzdCBDQTAgFw0yNjEwMTgxODI3NTJaGA8yMTI2MDkyNDE4Mjc1
        MlowHzEdMBsGA1UEAwwUU3Rlbm9ncmFwaGVyIFRlc3QgQ0EwggFLMIIBAwYHKoZI
        zj0CATCB9wIBATAsBgcqhkjOPQEBAiEA/////wAAAAEAAAAAAAAAAAAAAAD/////
        //////////8wWwQg/////wAAAAEAAAAAAAAAAAAAAAD///////////////wEIFrG
        NdiqOpPns+u9VXaYhrxlHQawzFOw9jvOPD4n0mBLAxUAxJ02CIbnBJNqZnjhE50m
        t4GffpAEQQRrF9Hy4SxCR/i85uVjpEDydwN9gS3rM6D0oTlF2JjClk/jQuL+Gn+b
        jufrSnwPnhYrzjNXazFezsu2QGg3v1H1AiEA/////wAAAAD//////////7zm+q2n
        F56E87nKwvxjJVECAQEDQgAEejtxQyvQeRxPNxBaD3TUbhUgcicpQeuypA++98G+
        6iuLn/EciemuSh8Ke7gcwGNp3QU2+BJlVKbPe39W4/zbSjAKBggqhkjOPQQDAgNI
        ADBFAiBLOdC51zPKb5w/GcPpLS5bjYeoujHoPSr++V/B70CUFwIhAO9xnGhauz8y
        r8MSn/YpJuKPNcW3JtyroHWtb7kkyDid
        -----END CERTIFICATE-----
        """

    func testNoEnvironmentLeavesTheSystemInCharge() {
        let network = UpstreamNetwork.from(env: [:])
        XCTAssertNil(network.proxyDictionary)
        XCTAssertTrue(network.extraAnchors.isEmpty)
    }

    func testHTTPSProxyGoesIntoTheSessionWithNoProxyAsExceptions() throws {
        let network = UpstreamNetwork.from(env: [
            "HTTPS_PROXY": "http://proxy.corp:3128", "no_proxy": ".internal.corp, build.corp"
        ])
        let proxies = try XCTUnwrap(network.proxyDictionary)
        XCTAssertEqual(proxies[kCFNetworkProxiesHTTPSProxy as String] as? String, "proxy.corp")
        XCTAssertEqual(proxies[kCFNetworkProxiesHTTPSPort as String] as? Int, 3128)
        XCTAssertEqual(proxies[kCFNetworkProxiesHTTPSEnable as String] as? Int, 1)
        XCTAssertNil(proxies[kCFNetworkProxiesHTTPProxy as String])
        let exceptions = try XCTUnwrap(proxies[kCFNetworkProxiesExceptionsList as String] as? [String])
        XCTAssertTrue(exceptions.contains("*.internal.corp"))
        XCTAssertTrue(exceptions.contains("build.corp"))
        XCTAssertTrue(exceptions.contains("127.0.0.1"), "a local provider is never proxied")
    }

    func testABareHostPortAndItsCredentialsAreAccepted() {
        let network = UpstreamNetwork.from(env: ["https_proxy": "me%40corp:p%3Ass@proxy.corp:8080"])
        XCTAssertEqual(network.httpsProxy,
                       UpstreamNetwork.Proxy(host: "proxy.corp", port: 8080, user: "me@corp", password: "p:ss"))
        let credential = network.proxyCredential(host: "PROXY.corp", port: 8080)
        XCTAssertEqual(credential?.user, "me@corp")
        XCTAssertEqual(credential?.password, "p:ss")
        XCTAssertNil(network.proxyCredential(host: "proxy.corp", port: 9999))
    }

    func testNoProxyStarTurnsTheProxyOff() {
        let network = UpstreamNetwork.from(env: ["HTTPS_PROXY": "http://proxy.corp:3128", "NO_PROXY": "*"])
        XCTAssertNil(network.proxyDictionary)
    }

    func testExtraCACertificatesAreRead() {
        let path = tmpDir.appendingPathComponent("ca.pem").path
        let bundle = Data((Self.pem + "\n# a comment\n" + Self.pem).utf8)
        let network = UpstreamNetwork.from(env: ["NODE_EXTRA_CA_CERTS": path]) { $0 == path ? bundle : nil }
        XCTAssertEqual(network.extraAnchors.count, 2)
    }

    func testAnUnreadableCAFileAddsNothing() {
        let network = UpstreamNetwork.from(env: ["NODE_EXTRA_CA_CERTS": "/nonexistent/ca.pem"])
        XCTAssertTrue(network.extraAnchors.isEmpty)
    }

    func testSettingsEnvOverridesTheProcessEnvironment() throws {
        let settings = tmpDir.appendingPathComponent("settings.json")
        let json: [String: Any] = ["env": ["HTTPS_PROXY": "http://from-settings.corp:3128", "OTHER": 1]]
        try JSONSerialization.data(withJSONObject: json).write(to: settings)
        let network = UpstreamNetwork.current(settingsURL: settings)
        XCTAssertEqual(network.httpsProxy?.host, "from-settings.corp")
    }

    func testAProxyChallengeIsAnsweredWithTheProxysCredentials() {
        let network = UpstreamNetwork.from(env: ["HTTPS_PROXY": "http://me:pw@proxy.corp:3128"])
        let space = URLProtectionSpace(proxyHost: "proxy.corp", port: 3128, type: NSURLProtectionSpaceHTTPSProxy,
                                       realm: nil, authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
        let challenge = URLAuthenticationChallenge(
            protectionSpace: space, proposedCredential: nil, previousFailureCount: 0,
            failureResponse: nil, error: nil, sender: ChallengeSender())
        let (disposition, credential) = UpstreamTrust(network: network).answer(challenge)
        XCTAssertEqual(disposition, .useCredential)
        XCTAssertEqual(credential?.user, "me")
    }
}

private final class ChallengeSender: NSObject, URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
    func cancel(_ challenge: URLAuthenticationChallenge) {}
}
