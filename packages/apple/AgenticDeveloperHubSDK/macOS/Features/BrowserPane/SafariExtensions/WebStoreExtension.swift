//
//  WebStoreExtension.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// The Chrome Web Store, as far as a Safari pane needs it: which extension a
/// link or an ID names, where Google serves its package, and the zip inside
/// that package. Pure, so every rule here is a unit test away.
public enum WebStoreExtension {

    /// Why a Web Store extension could not be fetched or unpacked.
    public enum Failure: Error, Equatable, LocalizedError {
        /// The text names no extension: neither an ID nor a Web Store link.
        case notAnExtension(String)
        /// What came back is not a CRX package or a zip.
        case notAPackage
        /// A CRX header claims more bytes than the package holds.
        case truncatedPackage
        /// The package has no `manifest.json` once unpacked.
        case noManifest
        /// Google answered with something other than the package.
        case download(String)
        /// Unzipping failed.
        case unpack(String)

        public var errorDescription: String? {
            switch self {
            case .notAnExtension(let text): "“\(text)” is not a Chrome Web Store link or extension ID."
            case .notAPackage: "The Chrome Web Store did not send an extension package."
            case .truncatedPackage: "The extension package is incomplete."
            case .noManifest: "The extension package has no manifest.json."
            case .download(let detail): "The extension could not be downloaded: \(detail)"
            case .unpack(let detail): "The extension could not be unpacked: \(detail)"
            }
        }
    }

    /// The store's address, where Get Extensions… goes.
    public static let storeURL = URL(string: "https://chromewebstore.google.com/category/extensions")!

    /// The Chrome version the download asks as. Google serves the newest
    /// package that version may run, and refuses one whose
    /// `minimum_chrome_version` is above it, so it is kept current-ish.
    static let chromeVersion = "142.0.0.0"

    /// Whether `text` is a Chrome extension ID: 32 letters from a to p.
    public static func isExtensionID(_ text: String) -> Bool {
        text.count == 32 && text.allSatisfy { ("a"..."p").contains($0) }
    }

    /// The extension `text` names: a bare ID, or a Web Store detail link
    /// (`chromewebstore.google.com/detail/<slug>/<id>`, the old
    /// `chrome.google.com/webstore/detail/…`, with or without the slug).
    public static func id(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if isExtensionID(trimmed) { return trimmed }
        guard let url = URL(string: trimmed), isStoreHost(url.host) else { return nil }
        return id(inStorePath: url)
    }

    /// The extension a Web Store page is about, when it is a detail page.
    public static func detailID(of url: URL?) -> String? {
        guard let url, isStoreHost(url.host) else { return nil }
        return id(inStorePath: url)
    }

    /// Where Google serves `id`'s package: the update service, asked for the
    /// CRX3 an on-demand install gets.
    public static func downloadURL(id: String) -> URL {
        // `x` carries a query of its own, so its `=` and `&` go escaped.
        URL(string: "https://clients2.google.com/service/update2/crx?response=redirect"
            + "&prodversion=\(chromeVersion)&acceptformat=crx2,crx3"
            + "&x=id%3D\(id)%26installsource%3Dondemand%26uc")!
    }

    /// The update service asked whether `id` has a version newer than
    /// `version`: the protocol Chrome's own updater speaks, answered with a
    /// short XML document instead of the package.
    public static func updateCheckURL(id: String, version: String) -> URL {
        let escaped = version.addingPercentEncoding(
            withAllowedCharacters: .alphanumerics.union(.init(charactersIn: "."))) ?? version
        return URL(string: "https://clients2.google.com/service/update2/crx?prodversion=\(chromeVersion)"
            + "&acceptformat=crx2,crx3&x=id%3D\(id)%26v%3D\(escaped)%26installsource%3Dondemand%26uc")!
    }

    /// The version an update check offers, or nil when it says there is
    /// none (`status="noupdate"`) or is not an update response at all.
    public static func offeredVersion(inUpdateResponse data: Data) -> String? {
        guard let text = String(data: data, encoding: .utf8),
              let check = text.range(of: #"<updatecheck\b[^>]*>"#, options: .regularExpression) else { return nil }
        let element = String(text[check])
        guard attribute("status", in: element) == "ok" else { return nil }
        return attribute("version", in: element)
    }

    private static func attribute(_ name: String, in element: String) -> String? {
        guard let match = element.range(of: "\\b\(name)=\"[^\"]*\"", options: .regularExpression) else { return nil }
        return String(element[match].dropFirst(name.count + 2).dropLast())
    }

    /// Whether `offered` is a later version than `installed`, comparing the
    /// dot-separated numbers Chrome's manifests use, a missing part as 0.
    public static func isNewer(_ offered: String, than installed: String) -> Bool {
        let lhs = offered.split(separator: ".").map { Int($0) ?? 0 }
        let rhs = installed.split(separator: ".").map { Int($0) ?? 0 }
        for index in 0..<max(lhs.count, rhs.count) {
            let left = index < lhs.count ? lhs[index] : 0
            let right = index < rhs.count ? rhs[index] : 0
            if left != right { return left > right }
        }
        return false
    }

    /// The zip inside a CRX package. CRX3 is `Cr24`, version 3, a header
    /// length and the header (signatures, protobuf); CRX2 is `Cr24`,
    /// version 2, a key length, a signature length and the two. A plain zip
    /// (`PK`) is its own payload.
    public static func zipPayload(ofCRX data: Data) throws -> Data {
        let bytes = [UInt8](data)
        if bytes.starts(with: [0x50, 0x4B]) { return data }
        guard bytes.starts(with: Array("Cr24".utf8)), bytes.count >= 12 else { throw Failure.notAPackage }
        func word(at offset: Int) -> Int {
            Int(bytes[offset]) | Int(bytes[offset + 1]) << 8
                | Int(bytes[offset + 2]) << 16 | Int(bytes[offset + 3]) << 24
        }
        let start: Int
        switch word(at: 4) {
        case 3:
            start = 12 + word(at: 8)
        case 2:
            guard bytes.count >= 16 else { throw Failure.truncatedPackage }
            start = 16 + word(at: 8) + word(at: 12)
        default:
            throw Failure.notAPackage
        }
        guard start < bytes.count else { throw Failure.truncatedPackage }
        let payload = data.subdata(in: data.startIndex + start ..< data.endIndex)
        guard payload.starts(with: [0x50, 0x4B]) else { throw Failure.notAPackage }
        return payload
    }

    private static func isStoreHost(_ host: String?) -> Bool {
        host == "chromewebstore.google.com" || host == "chrome.google.com"
    }

    private static func id(inStorePath url: URL) -> String? {
        let parts = url.pathComponents.filter { $0 != "/" }
        guard let detail = parts.firstIndex(of: "detail") else { return nil }
        return parts[(detail + 1)...].first(where: isExtensionID)
    }
}
