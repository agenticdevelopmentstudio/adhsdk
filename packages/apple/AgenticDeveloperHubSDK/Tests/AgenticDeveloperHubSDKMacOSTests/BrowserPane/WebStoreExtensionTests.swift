import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// The Chrome Web Store rules a Safari pane installs by: which extension a
/// link or ID names, the update service's answers, version order, and the
/// zip inside a CRX package.
final class WebStoreExtensionTests: XCTestCase {

    private let darkReader = "eimadpbcbfnmbkopoojfekhnkhdbieeh"

    // MARK: - IDs and links

    func test_isExtensionID_acceptsThirtyTwoLettersFromAToP() {
        XCTAssertTrue(WebStoreExtension.isExtensionID(darkReader))
    }

    func test_isExtensionID_rejectsWrongLengthAndLettersPastP() {
        XCTAssertFalse(WebStoreExtension.isExtensionID(String(darkReader.dropLast())))
        XCTAssertFalse(WebStoreExtension.isExtensionID("z" + darkReader.dropFirst()))
        XCTAssertFalse(WebStoreExtension.isExtensionID(darkReader.uppercased()))
    }

    func test_idFrom_bareIDWithWhitespace() {
        XCTAssertEqual(WebStoreExtension.id(from: "  \(darkReader)\n"), darkReader)
    }

    func test_idFrom_currentDetailLinkWithSlug() {
        let link = "https://chromewebstore.google.com/detail/dark-reader/\(darkReader)?hl=en"
        XCTAssertEqual(WebStoreExtension.id(from: link), darkReader)
    }

    func test_idFrom_currentDetailLinkWithoutSlug() {
        XCTAssertEqual(WebStoreExtension.id(from: "https://chromewebstore.google.com/detail/\(darkReader)"), darkReader)
    }

    func test_idFrom_oldWebStoreLink() {
        let link = "https://chrome.google.com/webstore/detail/dark-reader/\(darkReader)"
        XCTAssertEqual(WebStoreExtension.id(from: link), darkReader)
    }

    func test_idFrom_rejectsOtherHostsAndNonDetailPages() {
        XCTAssertNil(WebStoreExtension.id(from: "https://example.com/detail/x/\(darkReader)"))
        XCTAssertNil(WebStoreExtension.id(from: "https://chromewebstore.google.com/category/extensions"))
        XCTAssertNil(WebStoreExtension.id(from: "dark reader"))
    }

    func test_detailID_onlyForStoreDetailPages() {
        let detail = URL(string: "https://chromewebstore.google.com/detail/dark-reader/\(darkReader)")
        XCTAssertEqual(WebStoreExtension.detailID(of: detail), darkReader)
        XCTAssertNil(WebStoreExtension.detailID(of: WebStoreExtension.storeURL))
        XCTAssertNil(WebStoreExtension.detailID(of: nil))
    }

    // MARK: - Update service

    func test_downloadURL_escapesTheNestedQuery() {
        let url = WebStoreExtension.downloadURL(id: darkReader).absoluteString
        XCTAssertTrue(url.hasPrefix("https://clients2.google.com/service/update2/crx?response=redirect"))
        XCTAssertTrue(url.contains("&x=id%3D\(darkReader)%26installsource%3Dondemand%26uc"))
    }

    func test_updateCheckURL_carriesTheInstalledVersion() {
        let url = WebStoreExtension.updateCheckURL(id: darkReader, version: "4.9.135").absoluteString
        XCTAssertTrue(url.contains("x=id%3D\(darkReader)%26v%3D4.9.135%26"))
        XCTAssertFalse(url.contains("response=redirect"))
    }

    func test_offeredVersion_readsAnOkUpdateCheck() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?><gupdate xmlns="http://www.google.com/update2/response" \
        protocol="2.0"><app appid="\(darkReader)" status="ok"><updatecheck codebase="https://x/y.crx" \
        version="4.9.140" status="ok"/></app></gupdate>
        """
        XCTAssertEqual(WebStoreExtension.offeredVersion(inUpdateResponse: Data(xml.utf8)), "4.9.140")
    }

    func test_offeredVersion_nilForNoUpdateOrGarbage() {
        let none = #"<gupdate><app status="ok"><updatecheck status="noupdate"/></app></gupdate>"#
        XCTAssertNil(WebStoreExtension.offeredVersion(inUpdateResponse: Data(none.utf8)))
        XCTAssertNil(WebStoreExtension.offeredVersion(inUpdateResponse: Data("<html></html>".utf8)))
    }

    // MARK: - Versions

    func test_isNewer_comparesNumbersNotStrings() {
        XCTAssertTrue(WebStoreExtension.isNewer("4.10.0", than: "4.9.135"))
        XCTAssertFalse(WebStoreExtension.isNewer("4.9.135", than: "4.10.0"))
    }

    func test_isNewer_missingPartsCountAsZero() {
        XCTAssertFalse(WebStoreExtension.isNewer("1.2", than: "1.2.0"))
        XCTAssertTrue(WebStoreExtension.isNewer("1.2.0.1", than: "1.2"))
    }

    func test_isNewer_equalIsNotNewer() {
        XCTAssertFalse(WebStoreExtension.isNewer("2.0", than: "2.0"))
    }

    // MARK: - CRX

    private let zip: [UInt8] = [0x50, 0x4B, 0x03, 0x04, 0xAA, 0xBB]

    private func littleEndian(_ value: Int) -> [UInt8] {
        (0..<4).map { UInt8((value >> ($0 * 8)) & 0xFF) }
    }

    func test_zipPayload_plainZipIsItsOwnPayload() throws {
        XCTAssertEqual(try WebStoreExtension.zipPayload(ofCRX: Data(zip)), Data(zip))
    }

    func test_zipPayload_skipsTheCRX3Header() throws {
        let header: [UInt8] = [1, 2, 3, 4, 5]
        let crx = Array("Cr24".utf8) + littleEndian(3) + littleEndian(header.count) + header + zip
        XCTAssertEqual(try WebStoreExtension.zipPayload(ofCRX: Data(crx)), Data(zip))
    }

    func test_zipPayload_skipsTheCRX2KeyAndSignature() throws {
        let key: [UInt8] = [9, 9, 9]
        let signature: [UInt8] = [7, 7]
        let crx = Array("Cr24".utf8) + littleEndian(2) + littleEndian(key.count) + littleEndian(signature.count)
            + key + signature + zip
        XCTAssertEqual(try WebStoreExtension.zipPayload(ofCRX: Data(crx)), Data(zip))
    }

    func test_zipPayload_headerLongerThanThePackageIsTruncated() {
        let crx = Array("Cr24".utf8) + littleEndian(3) + littleEndian(500) + zip
        XCTAssertThrowsError(try WebStoreExtension.zipPayload(ofCRX: Data(crx))) { error in
            XCTAssertEqual(error as? WebStoreExtension.Failure, .truncatedPackage)
        }
    }

    func test_zipPayload_rejectsWhatIsNotAPackage() {
        let html = Data("<html>Not found</html>".utf8)
        XCTAssertThrowsError(try WebStoreExtension.zipPayload(ofCRX: html)) { error in
            XCTAssertEqual(error as? WebStoreExtension.Failure, .notAPackage)
        }
        let crx4 = Array("Cr24".utf8) + littleEndian(4) + littleEndian(0) + zip
        XCTAssertThrowsError(try WebStoreExtension.zipPayload(ofCRX: Data(crx4))) { error in
            XCTAssertEqual(error as? WebStoreExtension.Failure, .notAPackage)
        }
    }
}
