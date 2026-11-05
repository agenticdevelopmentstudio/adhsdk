import Testing
import UIKit
import Foundation
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// Covers the iOS half of the `PlatformColor`/`PlatformFont` seam:
/// `SemanticPalette.platformColor(_:)`/`platformFont(_:)` forwarding onto
/// `uiColor(_:)`/`font(_:)`, and `UIFont.applying(bold:italic:)`.
@MainActor
@Suite("PlatformAppearance (iOS)")
struct PlatformAppearanceTests {

    private var palette: SemanticPalette { SemanticPalette(theme: BuiltInThemes.solarizedDark) }

    @Test("platformColor forwards to uiColor for the same role")
    func platformColorForwardsToUIColor() {
        #expect(palette.platformColor(.accent) == palette.uiColor(.accent))
        #expect(palette.platformColor(.personaText) == palette.uiColor(.personaText))
    }

    @Test("platformFont forwards to font for the same role")
    func platformFontForwardsToFont() {
        #expect(palette.platformFont(.body) == palette.font(.body))
        #expect(palette.platformFont(.code) == palette.font(.code))
    }

    @Test("applying(bold:italic:) with neither flag set returns the same font")
    func applyingNeitherIsNoOp() {
        let font = palette.font(.body)
        #expect(font.applying(bold: false, italic: false) == font)
    }

    @Test("applying(bold: true) sets the bold symbolic trait")
    func applyingBoldSetsTrait() {
        let font = palette.font(.body).applying(bold: true, italic: false)
        #expect(font.fontDescriptor.symbolicTraits.contains(.traitBold))
    }

    @Test("applying(italic: true) sets the italic symbolic trait")
    func applyingItalicSetsTrait() {
        let font = palette.font(.body).applying(bold: false, italic: true)
        #expect(font.fontDescriptor.symbolicTraits.contains(.traitItalic))
    }

    @Test("applying(bold: true, italic: true) sets both symbolic traits")
    func applyingBoldItalicSetsBothTraits() {
        let font = palette.font(.body).applying(bold: true, italic: true)
        #expect(font.fontDescriptor.symbolicTraits.contains(.traitBold))
        #expect(font.fontDescriptor.symbolicTraits.contains(.traitItalic))
    }
}
