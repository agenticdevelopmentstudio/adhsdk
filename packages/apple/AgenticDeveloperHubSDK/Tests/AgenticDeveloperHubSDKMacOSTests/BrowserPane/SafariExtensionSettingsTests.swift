import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// The rules behind a Safari extension's details page: what each site access
/// mode grants, what a typed site means, when file access is offered, and
/// that records saved before these settings existed still read.
final class SafariExtensionSettingsTests: XCTestCase {

    // MARK: - Site access

    func test_grantedOrigins_allSitesGrantsEverythingRequestedOnce() {
        let granted = SafariExtensionSettings.grantedOrigins(
            for: .allSites, requested: ["*://b.com/*", "*://a.com/*", "*://b.com/*"], sites: ["*://c.com/*"])
        XCTAssertEqual(granted, ["*://a.com/*", "*://b.com/*"])
    }

    func test_grantedOrigins_specificSitesGrantsOnlyTheListedSites() {
        let granted = SafariExtensionSettings.grantedOrigins(
            for: .specificSites, requested: ["<all_urls>"], sites: ["*://c.com/*", "*://c.com/*"])
        XCTAssertEqual(granted, ["*://c.com/*"])
    }

    func test_grantedOrigins_onClickGrantsNothing() {
        XCTAssertEqual(SafariExtensionSettings.grantedOrigins(
            for: .onClick, requested: ["<all_urls>"], sites: ["*://c.com/*"]), [])
    }

    // MARK: - Typed sites

    func test_sitePattern_aHostCoversEveryPageOnIt() {
        XCTAssertEqual(SafariExtensionSettings.sitePattern(from: "Example.com"), "*://example.com/*")
        XCTAssertEqual(SafariExtensionSettings.sitePattern(from: "*.example.com"), "*://*.example.com/*")
    }

    func test_sitePattern_aLinkBecomesItsSite() {
        XCTAssertEqual(SafariExtensionSettings.sitePattern(from: "https://example.com:8443/a/b?c"),
                       "*://example.com/*")
        XCTAssertEqual(SafariExtensionSettings.sitePattern(from: "example.com/path"), "*://example.com/*")
    }

    func test_sitePattern_keepsAMatchPattern() {
        XCTAssertEqual(SafariExtensionSettings.sitePattern(from: "https://*.example.com/docs/*"),
                       "https://*.example.com/docs/*")
        XCTAssertEqual(SafariExtensionSettings.sitePattern(from: "*://example.com"), "*://example.com/*")
        XCTAssertEqual(SafariExtensionSettings.sitePattern(from: "<all_urls>"), "<all_urls>")
        XCTAssertEqual(SafariExtensionSettings.sitePattern(from: "file:///Users/*"), "file:///Users/*")
    }

    func test_sitePattern_refusesTextThatNamesNoSite() {
        for text in ["", "   ", "two words", "chrome://extensions", "example..", ".example.com", "file://", "a_b.com"] {
            XCTAssertNil(SafariExtensionSettings.sitePattern(from: text), text)
        }
    }

    func test_sitePatterns_splitsOnCommasAndLinesKeepingOrderOnce() {
        let (patterns, invalid) = SafariExtensionSettings.sitePatterns(
            from: "b.com, a.com\nb.com,, not a site\n")
        XCTAssertEqual(patterns, ["*://b.com/*", "*://a.com/*"])
        XCTAssertEqual(invalid, ["not a site"])
    }

    @MainActor
    func test_typedPattern_showsAWholeSiteAsItsName() {
        XCTAssertEqual(SafariExtensionDetailsView.typed(pattern: "*://example.com/*"), "example.com")
        XCTAssertEqual(SafariExtensionDetailsView.typed(pattern: "https://example.com/*"), "https://example.com/*")
    }

    // MARK: - File access and descriptions

    func test_offersFileAccess_onlyForPatternsThatReachFiles() {
        XCTAssertTrue(SafariExtensionSettings.offersFileAccess(requested: ["<all_urls>"]))
        XCTAssertTrue(SafariExtensionSettings.offersFileAccess(requested: ["FILE:///*"]))
        XCTAssertFalse(SafariExtensionSettings.offersFileAccess(requested: ["*://*/*", "https://a.com/*"]))
    }

    func test_describeOrigin_readsAsSites() {
        XCTAssertEqual(SafariExtensionSettings.describe(origin: "<all_urls>"), "All sites")
        XCTAssertEqual(SafariExtensionSettings.describe(origin: "*://*/*"), "All sites")
        XCTAssertEqual(SafariExtensionSettings.describe(origin: "file:///*"), "Files on this Mac")
        XCTAssertEqual(SafariExtensionSettings.describe(origin: "https://*.example.com/x/*"), "*.example.com")
    }

    func test_describePermission_fallsBackToItsName() {
        XCTAssertEqual(SafariExtensionSettings.describe(permission: "storage"), "Store its own data")
        XCTAssertEqual(SafariExtensionSettings.describe(permission: "somethingNew"), "somethingNew")
    }

    // MARK: - Records

    func test_record_savedBeforeTheseSettingsReadsWithDefaults() throws {
        let original = SafariExtensionRecord(id: "abc", isEnabled: true, isFromWebStore: true)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        for key in ["siteAccess", "sites", "allowsFileAccess", "allowsPrivateBrowsing", "isPinned"] {
            json.removeValue(forKey: key)
        }
        let decoded = try JSONDecoder().decode(
            SafariExtensionRecord.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(decoded.siteAccess)
        XCTAssertEqual(decoded.effectiveSiteAccess, .allSites)
        XCTAssertNil(decoded.isPinned)
        XCTAssertNil(decoded.allowsFileAccess)
    }

    func test_record_roundTripsTheNewSettings() throws {
        var record = SafariExtensionRecord(id: "abc", isEnabled: true, isFromWebStore: true)
        record.siteAccess = .specificSites
        record.sites = ["*://a.com/*"]
        record.allowsFileAccess = true
        record.allowsPrivateBrowsing = true
        record.isPinned = false
        let decoded = try JSONDecoder().decode(SafariExtensionRecord.self, from: JSONEncoder().encode(record))
        XCTAssertEqual(decoded.siteAccess, .specificSites)
        XCTAssertEqual(decoded.sites, ["*://a.com/*"])
        XCTAssertEqual(decoded.allowsFileAccess, true)
        XCTAssertEqual(decoded.allowsPrivateBrowsing, true)
        XCTAssertEqual(decoded.isPinned, false)
    }
}
