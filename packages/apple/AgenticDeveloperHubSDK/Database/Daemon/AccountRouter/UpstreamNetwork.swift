#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import Security

/// The proxy and extra CA certificates Claude Code itself honours, so a
/// request it sends through the router reaches upstream the way it would have
/// without it: `HTTPS_PROXY`, `HTTP_PROXY`, `NO_PROXY` (either case) and
/// `NODE_EXTRA_CA_CERTS`.
///
/// The LaunchAgent gives the daemon no environment, so the values are read
/// from the daemon's environment overlaid by the `env` block of
/// `~/.claude/settings.json`, where Claude Code reads them too. They are read
/// once, when the router is made; a change takes effect at the next daemon
/// start. Loopback is never proxied: a local provider is reached directly.
struct UpstreamNetwork: Sendable {
    struct Proxy: Equatable, Sendable {
        let host: String
        let port: Int
        let user: String?
        let password: String?
    }

    var httpsProxy: Proxy?
    var httpProxy: Proxy?
    /// `NO_PROXY` as CFNetwork exception patterns (`.example.com` → `*.example.com`).
    var exceptions: [String] = []
    /// The certificates from `NODE_EXTRA_CA_CERTS`, trusted beside the system's.
    var extraAnchors: [SecCertificate] = []

    static let none = UpstreamNetwork()

    /// Hosts that are never proxied, whatever `NO_PROXY` says.
    private static let loopback = ["localhost", "127.0.0.1", "::1"]

    /// The daemon's environment overlaid by `settings.json`'s `env` block.
    static func current(
        settingsURL: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
    ) -> UpstreamNetwork {
        var env = ProcessInfo.processInfo.environment
        if let data = try? Data(contentsOf: settingsURL),
           let settings = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let block = settings["env"] as? [String: Any] {
            for (key, value) in block {
                if let text = value as? String { env[key] = text }
            }
        }
        return from(env: env)
    }

    static func from(
        env: [String: String],
        readFile: (String) -> Data? = { FileManager.default.contents(atPath: $0) }
    ) -> UpstreamNetwork {
        func value(_ name: String) -> String? {
            let found = (env[name] ?? env[name.lowercased()])?.trimmingCharacters(in: .whitespaces)
            return found?.isEmpty == false ? found : nil
        }
        var network = UpstreamNetwork()
        let noProxy = (value("NO_PROXY") ?? "")
            .split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if !noProxy.contains("*") {
            network.httpsProxy = value("HTTPS_PROXY").flatMap(proxy)
            network.httpProxy = value("HTTP_PROXY").flatMap(proxy)
        }
        network.exceptions = loopback + noProxy.map { $0.hasPrefix(".") ? "*" + $0 : $0 }
        if let path = value("NODE_EXTRA_CA_CERTS"), let pem = readFile(path) {
            network.extraAnchors = certificates(pem: pem)
        }
        return network
    }

    /// `http://user:pass@host:port`, or a bare `host:port` as curl and Node accept.
    private static func proxy(_ text: String) -> Proxy? {
        let withScheme = text.contains("://") ? text : "http://" + text
        guard let components = URLComponents(string: withScheme), let host = components.host, !host.isEmpty
        else { return nil }
        let port = components.port ?? (components.scheme == "https" ? 443 : 80)
        return Proxy(host: host, port: port, user: components.user?.removingPercentEncoding,
                     password: components.password?.removingPercentEncoding)
    }

    /// Every `CERTIFICATE` block in a PEM file; anything else is skipped.
    static func certificates(pem: Data) -> [SecCertificate] {
        guard let text = String(data: pem, encoding: .utf8) else { return [] }
        let begin = "-----BEGIN CERTIFICATE-----"
        let end = "-----END CERTIFICATE-----"
        var found: [SecCertificate] = []
        var rest = text[...]
        while let start = rest.range(of: begin),
              let stop = rest.range(of: end, range: start.upperBound..<rest.endIndex) {
            let body = rest[start.upperBound..<stop.lowerBound].filter { !$0.isWhitespace }
            if let der = Data(base64Encoded: String(body)),
               let certificate = SecCertificateCreateWithData(nil, der as CFData) {
                found.append(certificate)
            }
            rest = rest[stop.upperBound...]
        }
        return found
    }

    /// For `URLSessionConfiguration.connectionProxyDictionary`; nil leaves the
    /// system settings in charge.
    var proxyDictionary: [AnyHashable: Any]? {
        guard httpsProxy != nil || httpProxy != nil else { return nil }
        var dictionary: [AnyHashable: Any] = [kCFNetworkProxiesExceptionsList as String: exceptions]
        if let httpsProxy {
            dictionary[kCFNetworkProxiesHTTPSEnable as String] = 1
            dictionary[kCFNetworkProxiesHTTPSProxy as String] = httpsProxy.host
            dictionary[kCFNetworkProxiesHTTPSPort as String] = httpsProxy.port
        }
        if let httpProxy {
            dictionary[kCFNetworkProxiesHTTPEnable as String] = 1
            dictionary[kCFNetworkProxiesHTTPProxy as String] = httpProxy.host
            dictionary[kCFNetworkProxiesHTTPPort as String] = httpProxy.port
        }
        return dictionary
    }

    /// The proxy whose host and port a challenge names, when it carries a user.
    func proxyCredential(host: String, port: Int) -> URLCredential? {
        for proxy in [httpsProxy, httpProxy].compactMap({ $0 })
        where proxy.host.caseInsensitiveCompare(host) == .orderedSame && proxy.port == port {
            guard let user = proxy.user else { return nil }
            return URLCredential(user: user, password: proxy.password ?? "", persistence: .forSession)
        }
        return nil
    }
}

/// The session delegate that answers what `UpstreamNetwork` adds: a server
/// trust evaluated with the extra anchors as well as the system's, and the
/// proxy's own credentials. Everything else gets the default handling.
final class UpstreamTrust: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    private let network: UpstreamNetwork

    init(network: UpstreamNetwork) {
        self.network = network
    }

    func urlSession(
        _ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let (disposition, credential) = answer(challenge)
        completionHandler(disposition, credential)
    }

    func urlSession(
        _ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let (disposition, credential) = answer(challenge)
        completionHandler(disposition, credential)
    }

    func answer(_ challenge: URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        let space = challenge.protectionSpace
        if space.isProxy() {
            guard challenge.previousFailureCount == 0,
                  let credential = network.proxyCredential(host: space.host, port: space.port)
            else { return (.performDefaultHandling, nil) }
            return (.useCredential, credential)
        }
        guard space.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              !network.extraAnchors.isEmpty, let trust = space.serverTrust
        else { return (.performDefaultHandling, nil) }
        SecTrustSetAnchorCertificates(trust, network.extraAnchors as CFArray)
        SecTrustSetAnchorCertificatesOnly(trust, false)
        guard SecTrustEvaluateWithError(trust, nil) else { return (.cancelAuthenticationChallenge, nil) }
        return (.useCredential, URLCredential(trust: trust))
    }
}
#endif
