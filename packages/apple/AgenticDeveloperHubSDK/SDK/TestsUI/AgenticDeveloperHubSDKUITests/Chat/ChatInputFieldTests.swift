import Testing
import AppKit
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// The composer's block caret, and the baseline it has to be able to report.
///
/// Both halves are here because they are the same field: the caret is drawn by
/// `ChatInputField` itself (AppKit will not shape a field editor's insertion
/// point, and would not let a host turn its blink off), and the baseline comes
/// from the padded cell that draws the room the caret sits in.
@MainActor
@Suite("ChatInputField")
struct ChatInputFieldTests {

    private func makeManager() -> ThemeManager {
        ThemeManager(storage: InMemoryThemeStorage(activeThemeID: BuiltInThemes.solarizedDark.id))
    }

    private func makeField(text: String = "") -> ChatInputField {
        let field = ChatInputField(string: text)
        field.frame = NSRect(x: 0, y: 0, width: 300, height: 26)
        field.layoutSubtreeIfNeeded()
        return field
    }

    // MARK: The caret

    @Test("a plain field draws no block caret and adds no layer")
    func noCaretByDefault() {
        let manager = makeManager()
        let field = makeField()
        #expect(field.usesBlockCaret == false)
        #expect(field.caretLayer.superlayer == nil)
        withExtendedLifetime(manager) {}
    }

    @Test("turning the block caret on attaches it lit, and turning it off takes it away again")
    func caretPresenceFollowsTheFlag() {
        let manager = makeManager()
        let field = makeField()

        field.usesBlockCaret = true
        #expect(field.caretLayer.superlayer != nil)
        #expect(field.caretLayer.isHidden == false)

        field.usesBlockCaret = false
        #expect(field.caretLayer.superlayer == nil)
        #expect(field.caretLayer.isHidden)
        withExtendedLifetime(manager) {}
    }

    @Test("with blinking on, the caret goes dark and comes back")
    func caretBlinks() {
        let manager = makeManager()
        let field = makeField()
        field.usesBlockCaret = true
        #expect(field.caretLayer.isHidden == false)

        // Just past one half-period, so the first flip has certainly fired.
        pumpRunLoop(for: ChatInputField.caretBlinkHalfPeriod + 0.15)
        #expect(field.caretLayer.isHidden)

        pumpRunLoop(for: ChatInputField.caretBlinkHalfPeriod + 0.15)
        #expect(field.caretLayer.isHidden == false)
        withExtendedLifetime(manager) {}
    }

    /// The "Blink caret" switch a host surfaces. AppKit offers no way to stop a
    /// field editor's insertion point blinking, which is half the reason the
    /// caret is drawn here at all.
    @Test("with blinking off, the caret parks lit and stays lit")
    func caretCanParkSolid() {
        let manager = makeManager()
        let field = makeField()
        field.usesBlockCaret = true
        field.caretBlinks = false

        pumpRunLoop(for: ChatInputField.caretBlinkHalfPeriod * 2 + 0.2)
        #expect(field.caretLayer.isHidden == false)
        withExtendedLifetime(manager) {}
    }

    @Test("switching blinking back on resumes it from lit")
    func blinkingResumes() {
        let manager = makeManager()
        let field = makeField()
        field.usesBlockCaret = true
        field.caretBlinks = false
        pumpRunLoop(for: 0.1)

        field.caretBlinks = true
        #expect(field.caretLayer.isHidden == false)
        pumpRunLoop(for: ChatInputField.caretBlinkHalfPeriod + 0.15)
        #expect(field.caretLayer.isHidden)
        withExtendedLifetime(manager) {}
    }

    @Test("the caret sits after the text, one character wide, and moves as the text grows")
    func caretTracksTheText() {
        let manager = makeManager()
        let field = makeField()
        field.usesBlockCaret = true

        field.stringValue = ""
        field.positionCaret()
        let atStart = field.caretLayer.frame

        field.stringValue = "olylo"
        field.positionCaret()
        let afterText = field.caretLayer.frame

        #expect(afterText.minX > atStart.minX)
        #expect(atStart.width > 0)
        #expect(atStart.height > 0)
        // One character cell, measured from the live font — a fixed width would
        // sit under half a glyph the moment a theme scales its type.
        let cell = ("0" as NSString).size(withAttributes: [.font: field.font!]).width
        #expect(abs(atStart.width - cell) < 0.5)
        withExtendedLifetime(manager) {}
    }

    /// Past the field's width AppKit scrolls the field editor instead of
    /// shrinking the type, and the caret is a sublayer of the *field* — so an
    /// unadjusted advance walks it off the right edge, where the field's own
    /// clipping erases it. A terminal chat with a long line would simply lose
    /// its cursor.
    @Test("the caret stays inside the field when the text runs past its width")
    func caretStaysInsideAnOverflowingField() {
        let manager = makeManager()
        let field = makeField()
        field.usesBlockCaret = true

        field.stringValue = String(repeating: "olylo ", count: 60)
        field.positionCaret()

        #expect(field.caretLayer.frame.maxX <= field.bounds.maxX)
        #expect(field.caretLayer.frame.minX >= field.bounds.minX)
        #expect(field.caretLayer.frame.width > 0)
        withExtendedLifetime(manager) {}
    }

    @Test("the caret is painted, not transparent")
    func caretHasInk() {
        let manager = makeManager()
        let field = makeField()
        field.usesBlockCaret = true
        #expect(field.caretLayer.backgroundColor != nil)
        #expect((field.caretLayer.backgroundColor?.alpha ?? 0) > 0)
        withExtendedLifetime(manager) {}
    }

    // MARK: The baseline

    /// A regression, and the reason the cell clamps its inset.
    ///
    /// AppKit asks the cell for its baseline with a probe rect narrower than
    /// the horizontal inset (4×16, measured). An unclamped `insetBy` inverts
    /// that rect, `NSTextFieldCell` answers with an infinite origin, and the
    /// infinity comes straight back out as the field's baseline. Any
    /// `.firstBaseline` stack then hands it to the layout engine, which
    /// rejects it — `Invalid parameter not satisfying: isfinite(c)` — and
    /// takes the process down.
    @Test("reports finite baselines despite the cell's padding")
    func baselinesAreFinite() {
        let manager = makeManager()
        let field = makeField(text: "olylo")
        #expect(field.firstBaselineOffsetFromTop.isFinite)
        #expect(field.lastBaselineOffsetFromBottom.isFinite)
        withExtendedLifetime(manager) {}
    }

    @Test("the padding shows up in the baseline rather than being lost")
    func baselineIncludesThePadding() {
        let manager = makeManager()
        let field = makeField(text: "olylo")
        let plain = NSTextField(string: "olylo")
        plain.font = field.font
        // The prompt is aligned against this number; if the padded field
        // reported the unpadded baseline, the glyph would sit high by exactly
        // the inset.
        #expect(field.firstBaselineOffsetFromTop > plain.firstBaselineOffsetFromTop)
        withExtendedLifetime(manager) {}
    }

    /// The composer aligns the prompt by constraining its baseline anchor to
    /// this field's, then pushing it down by the glyph's own centring drop —
    /// which only works if a padded field publishes a baseline anchor Auto
    /// Layout can solve against. This is that arrangement, in miniature.
    @Test("its baseline anchor can carry the prompt, offset and all")
    func carriesAnOffsetPromptBaseline() {
        let manager = makeManager()
        let field = makeField(text: "olylo")
        field.translatesAutoresizingMaskIntoConstraints = false
        let prompt = NSTextField(labelWithString: "\u{276F}")
        prompt.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 40))
        container.addSubview(prompt)
        container.addSubview(field)
        let drop: CGFloat = 3
        NSLayoutConstraint.activate([
            prompt.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            field.leadingAnchor.constraint(equalTo: prompt.trailingAnchor),
            field.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            field.topAnchor.constraint(equalTo: container.topAnchor),
            field.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            prompt.firstBaselineAnchor.constraint(
                equalTo: field.firstBaselineAnchor, constant: drop)
        ])
        container.layoutSubtreeIfNeeded()

        #expect(field.frame.origin.y.isFinite)
        #expect(prompt.frame.origin.y.isFinite)

        // The drop must actually reach the glyph: an unsatisfiable baseline
        // constraint would leave the two sitting on the same line.
        func depth(_ label: NSTextField) -> CGFloat {
            let box = label.convert(label.bounds, to: container)
            let top = container.isFlipped ? box.minY : container.bounds.maxY - box.maxY
            return top + label.firstBaselineOffsetFromTop
        }
        #expect(abs((depth(prompt) - depth(field)) - drop) < 0.5)
        withExtendedLifetime(manager) {}
    }
}
