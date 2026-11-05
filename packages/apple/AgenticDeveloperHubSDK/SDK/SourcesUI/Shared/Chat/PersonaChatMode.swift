import Foundation
import AgenticDeveloperHubSDK

/// Mirrors web's `PersonaChat.tsx` mode vocabulary: `inline` (the compact
/// desktop surface), `threePane` (the full desktop layout — see
/// `ThreePaneChatView`'s doc for its current stub state), and `mobile` (the
/// full-screen phone surface — see `MobileChatViewController`).
///
/// A plain, Foundation-only enum so it compiles for macOS and iOS both, and
/// a host can hold one value across both platforms. Each platform's factory
/// below is total: every case maps to something concrete on every platform,
/// even where that mapping is "not this platform's idiom, so reuse X" —
/// see each factory's doc for the exact reasoning.
public enum PersonaChatMode: Sendable {
    case inline
    case threePane
    case mobile
}

#if os(macOS)
import AppKit

extension PersonaChatMode {
    /// Builds the view for this mode on macOS. Total: every case maps to a
    /// concrete `NSView`.
    ///
    /// `.inline` and `.threePane` return their own views. `.mobile` returns
    /// `InlineChatView` — a phone-style full-screen overlay is not a
    /// desktop idiom, and inline is the desktop's own compact surface, so
    /// that's what a desktop host gets when it asks for `.mobile`.
    @MainActor
    public func makeView(viewModel: any ChatViewModel, localParticipantID: String) -> NSView {
        switch self {
        case .inline, .mobile:
            return InlineChatView(viewModel: viewModel, localParticipantID: localParticipantID)
        case .threePane:
            return ThreePaneChatView(viewModel: viewModel, localParticipantID: localParticipantID)
        }
    }
}
#endif

#if os(iOS)
import UIKit

extension PersonaChatMode {
    /// Builds the view controller for this mode on iOS. Total: every case
    /// returns `MobileChatViewController`, because the phone has exactly
    /// one chat surface — the mode vocabulary exists so a host can hold one
    /// `PersonaChatMode` value across both platforms, not because iOS has
    /// three layouts of its own.
    @MainActor
    public func makeViewController(viewModel: any ChatViewModel, localParticipantID: String) -> UIViewController {
        MobileChatViewController(viewModel: viewModel, localParticipantID: localParticipantID)
    }
}
#endif
