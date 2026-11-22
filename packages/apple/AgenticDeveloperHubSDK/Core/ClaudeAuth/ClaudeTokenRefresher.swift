import Foundation

/// Spends one saved login's refresh token for a fresh access/refresh pair.
///
/// **A refresh token is single-use.** A successful refresh voids the one that
/// was spent, so whatever comes back has to reach the Keychain before anything
/// else is allowed to fail — a rotation that is used and then dropped leaves
/// that saved login permanently dead, recoverable by nothing short of a browser
/// login.
///
/// Nothing in this process can do that writing: the Keychain items belong to the
/// menu-bar app, which is the only process macOS will let near them. That is why
/// this type has exactly one caller — ``ClaudeAuthEvaluator``, which runs only
/// inside a request the app made and returns every rotation in that request's
/// reply. Refreshing anywhere the answer cannot be returned to its owner is how a
/// login gets killed, which is also why the evaluator refuses to refresh a
/// credential that arrived without the Keychain item key naming where its
/// replacement would go.
///
/// The reply is the only route back, and it is not guaranteed to arrive: a caller
/// that times out or a connection that drops takes the rotation with it. Nothing
/// can make that lossless — the token is spent the moment the endpoint answers —
/// so what the design can do is keep the window small, which is why a round
/// refreshes its logins concurrently rather than one after another.
///
/// This is Claude Code's own OAuth client talking to Claude Code's own token
/// endpoint: the credential being refreshed is a login `claude` created, and
/// nothing here mints or owns anything of Stenographer's.
public enum ClaudeTokenRefresher {

    public static let tokenURL = URL(string: "https://platform.claude.com/v1/oauth/token")!
    public static let clientID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
    /// The beta header the official client sends for OAuth-token calls, wanted
    /// by this endpoint and by the messages probe alike.
    public static let beta = "oauth-2025-04-20"
    /// Cloudflare sits in front of both endpoints and rejects a default client
    /// signature outright (403, "error code: 1010") before it ever reads the
    /// request, so every call from this app names itself.
    public static let userAgent = "Stenographer (macOS)"

    private static let timeout: TimeInterval = 15

    /// Access tokens have been eight hours for as long as this endpoint has
    /// existed, so a response that omits `expires_in` is stamped with that
    /// rather than left carrying the old expiry. Keeping an OLD expiry against
    /// a NEW token is the worse of the two failures: the credential reads as
    /// already stale, so the next probe refreshes again and burns another
    /// single-use refresh token, every time, forever.
    private static let assumedAccessLife: TimeInterval = 8 * 3600

    /// How close to its expiry an access token may get before it is refreshed
    /// instead of used. A probe started inside this window would very likely
    /// arrive after the token had died.
    public static let refreshMargin: TimeInterval = 5 * 60

    /// Whether this credential's access token is still worth sending.
    ///
    /// An unknown expiry counts as usable: the round-trip answers the question
    /// for certain, and refreshing on a guess would spend a refresh token to
    /// learn what a 401 would have told us for free.
    ///
    /// `margin` widens ``refreshMargin`` for a caller that needs the token to
    /// outlive more than one probe — never narrows it.
    public static func isAccessTokenUsable(
        _ credential: ClaudeOAuthCredential, now: Date = Date(), margin: TimeInterval? = nil
    ) -> Bool {
        guard let expiry = credential.expirySeconds else { return true }
        return expiry - now.timeIntervalSince1970 > max(refreshMargin, margin ?? 0)
    }

    /// Exchanges `credential`'s refresh token for a fresh pair.
    ///
    /// Throws `ClaudeOAuthRefreshError`, whose three cases mean three different
    /// things to a caller — see that type. On success the returned credential is
    /// the stored one with the response's fields folded in, and the caller MUST
    /// store it.
    public static func refresh(
        _ credential: ClaudeOAuthCredential, now: Date = Date()
    ) async throws -> ClaudeOAuthCredential {
        var request = URLRequest(url: tokenURL, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(beta, forHTTPHeaderField: "anthropic-beta")
        request.setValue(userAgent, forHTTPHeaderField: "user-agent")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "grant_type": "refresh_token",
            "refresh_token": credential.refreshToken,
            "client_id": clientID
        ])

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError where neverSent(error.code) {
            throw ClaudeOAuthRefreshError.unsent(error.localizedDescription)
        } catch {
            throw ClaudeOAuthRefreshError.inconclusive(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else {
            throw ClaudeOAuthRefreshError.inconclusive("the token endpoint answered with no status")
        }
        if let refusal = refusal(status: http.statusCode, body: data) { throw refusal }

        guard let body = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let access = body["access_token"] as? String, !access.isEmpty
        else {
            // Caught here and nowhere deeper. By this point the refresh token is
            // already spent, so a failure further along would abandon whatever
            // the response did carry and void the stored credential for nothing.
            throw ClaudeOAuthRefreshError.inconclusive("the token endpoint returned no access token")
        }
        return rotated(credential, with: body, accessToken: access, now: now)
    }

    /// What a non-2xx answer from the token endpoint means, or nil for a 2xx.
    ///
    /// **Only a refused grant is `.spent`**: a 401, or a 400 naming
    /// `invalid_grant`. The rest of the 4xx range says nothing about the refresh
    /// token — Cloudflare's 403 "error code: 1010" never reaches the endpoint at
    /// all, and a 408 is an edge timing out — and reporting a good login dead
    /// sends the user through a browser login it never needed.
    public static func refusal(status: Int, body: Data) -> ClaudeOAuthRefreshError? {
        switch status {
        case 200..<300:
            return nil
        case 429:
            // Says nothing at all about the grant: a rate limit on the caller.
            return .rateLimited
        case 401:
            return .spent
        case 400 where oauthError(in: body) == "invalid_grant":
            return .spent
        default:
            return .inconclusive("HTTP \(status)")
        }
    }

    /// The OAuth `error` code in a token-endpoint reply, if it carries one.
    private static func oauthError(in body: Data) -> String? {
        (try? JSONSerialization.jsonObject(with: body) as? [String: Any])?["error"] as? String
    }

    /// Whether a transport failure proves the request never left this Mac — so
    /// the refresh token it carried was certainly not spent. A timeout or a
    /// dropped connection proves nothing: the endpoint may have answered into
    /// the void.
    public static func neverSent(_ code: URLError.Code) -> Bool {
        [.notConnectedToInternet, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed,
         .internationalRoamingOff, .dataNotAllowed].contains(code)
    }

    /// The stored credential with a refresh response's rotated pair folded in.
    ///
    /// Only the fields the response speaks to move — everything else is carried
    /// forward, because this credential goes back into Claude Code's own format
    /// and rebuilding it from what we happen to know would drop what we do not.
    public static func rotated(
        _ credential: ClaudeOAuthCredential,
        with body: [String: Any],
        accessToken: String,
        now: Date = Date()
    ) -> ClaudeOAuthCredential {
        var fresh = credential
        fresh.accessToken = accessToken
        if let rotatedRefresh = body["refresh_token"] as? String, !rotatedRefresh.isEmpty {
            fresh.refreshToken = rotatedRefresh
        }
        let seconds = now.timeIntervalSince1970
        // Milliseconds, which is how Claude Code writes both expiries.
        let life = (body["expires_in"] as? Double) ?? assumedAccessLife
        fresh.expiresAt = (seconds + life) * 1000
        if let refreshLife = body["refresh_token_expires_in"] as? Double {
            fresh.refreshTokenExpiresAt = (seconds + refreshLife) * 1000
        }
        if let scope = body["scope"] as? String, !scope.isEmpty {
            fresh.scopes = scope.split(separator: " ").map(String.init)
        }
        return fresh
    }
}

/// Why a refresh didn't produce a credential — three answers a caller has to
/// treat differently, not one failure.
public enum ClaudeOAuthRefreshError: Error, LocalizedError {

    /// A 401, or a 400 naming `invalid_grant`. Conclusive: this account logged in or refreshed
    /// somewhere else, which voids every older copy of its refresh token. The
    /// saved login will never work again and needs re-saving from a fresh login.
    case spent
    /// HTTP 429. The caller is rate limited; the credential is untouched and
    /// must not be marked dead.
    case rateLimited
    /// A 5xx, an unexplained 4xx, a timeout, or a reply we couldn't read. Try
    /// again later — but the refresh token may already be spent.
    case inconclusive(String)
    /// The request never left this Mac (offline, no DNS), so the refresh token
    /// is certainly untouched.
    case unsent(String)

    /// Whether the refresh token is certainly as unspent as before the attempt.
    public var leftTokenUntouched: Bool {
        switch self {
        case .rateLimited, .unsent: return true
        case .spent, .inconclusive: return false
        }
    }

    public var errorDescription: String? {
        switch self {
        case .spent:
            return "This saved login was spent elsewhere — logging in or refreshing on "
                + "another machine voids every older copy of its refresh token. Save the "
                + "account again after a fresh login."
        case .rateLimited:
            return "Anthropic rate-limited the token refresh. The saved login is fine; "
                + "this will work again shortly."
        case .inconclusive(let reason), .unsent(let reason):
            return "Couldn't refresh this saved login: \(reason)"
        }
    }

    /// Short enough for the quota card's one error line.
    public var shortText: String {
        switch self {
        case .spent: return "login spent elsewhere — save it again"
        case .rateLimited: return "rate limited — not a credential problem"
        case .inconclusive(let reason), .unsent(let reason): return reason.shortened()
        }
    }
}
