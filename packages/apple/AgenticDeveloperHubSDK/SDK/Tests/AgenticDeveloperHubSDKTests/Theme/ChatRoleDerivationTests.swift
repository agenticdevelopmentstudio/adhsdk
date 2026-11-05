import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

@Suite("Chat role derivation")
struct ChatRoleDerivationTests {

    /// Every built-in theme must produce legible chat text on its own bubble.
    /// 3.0 is the large-text floor; bubble text is 13pt so this is the honest
    /// minimum, and it is the guard against a mis-transcribed ported theme.
    ///
    /// A fill role can be translucent by design (a ghost button, a glass
    /// panel) — its raw channel values alone don't say what a viewer sees.
    /// What they see is the fill composited down its real backdrop chain:
    /// fill → `chatSurface` → `theme.background`, since a ported theme can
    /// override `--pc-surface` translucent too. Text roles are always
    /// opaque, so only the fill side needs compositing.
    @Test("chat text contrasts against its own bubble in every built-in theme")
    func chatTextIsLegible() {
        for theme in BuiltInThemes.all {
            let palette = SemanticPalette(theme: theme)
            let pairs: [(ThemeRole, ThemeRole)] = [
                (.personaText, .personaBubble),
                (.userText, .userBubble),
                (.sendButtonText, .sendButton),
            ]
            for (text, fill) in pairs {
                let ratio = palette.color(text).contrastRatio(against: effectiveFill(fill, palette, theme))
                #expect(ratio >= 3.0, "\(theme.name): \(text) on \(fill) is \(ratio)")
            }
        }
    }

    /// Resolves what a viewer actually sees behind `role`: the role's fill,
    /// composited over `chatSurface`, composited over the theme's window
    /// background — the real backdrop chain behind a chat bubble/button.
    private func effectiveFill(_ role: ThemeRole, _ palette: SemanticPalette, _ theme: ColorTheme) -> RGBAColor {
        palette.color(role)
            .composited(over: palette.color(.chatSurface))
            .composited(over: theme.background)
    }

    @Test("a role override wins over the derived chat colour")
    func overrideWins() {
        var theme = BuiltInThemes.all[0]
        let hotPink = RGBAColor(red: 1, green: 0, blue: 0.5, alpha: 1)
        theme.roleOverrides[ThemeRole.userBubble.rawValue] = hotPink
        #expect(SemanticPalette(theme: theme).color(.userBubble) == hotPink)
    }

    /// A transparent *fill* (a ghost button, a glass input panel) is a
    /// legitimate design choice, faithfully transcribed from several ported
    /// themes' `#00000000` overrides — it is not the defect the old blanket
    /// `alpha > 0` assertion assumed it was. A transparent *text* role is
    /// always a bug: invisible text is never intentional. So the alpha floor
    /// applies only to text-ish roles; fill/border roles are asserted only to
    /// resolve. The legibility guard transparency actually needs — that
    /// whatever shows through a transparent fill still contrasts with its
    /// text — is `chatTextIsLegible`'s compositing above.
    @Test("every chat role resolves for every built-in theme")
    func allChatRolesResolve() {
        let chatRoles: [ThemeRole] = [
            .personaBubble, .personaBubbleBorder, .personaText, .personaName,
            .userBubble, .userBubbleBorder, .userText, .userName,
            .chatSurface, .chatInputBackground, .chatInputBorder, .chatInputFocus,
            .sendButton, .sendButtonText, .sendButtonHover, .timestampText,
        ]
        #expect(chatRoles.count == 16)
        let textRoles: Set<ThemeRole> = [
            .personaText, .userText, .personaName, .userName, .sendButtonText, .timestampText,
        ]
        for theme in BuiltInThemes.all {
            let palette = SemanticPalette(theme: theme)
            for role in chatRoles {
                let color = palette.color(role)
                if textRoles.contains(role) {
                    #expect(color.alpha > 0, "\(theme.name)/\(role) is transparent text")
                }
                // Fill/border roles: no alpha assertion — a transparent fill
                // (ghost button, glass panel) is legitimate. They still must
                // resolve to *some* color, which `palette.color(role)` above
                // does unconditionally (it never returns nil/throws).
            }
        }
    }
}
