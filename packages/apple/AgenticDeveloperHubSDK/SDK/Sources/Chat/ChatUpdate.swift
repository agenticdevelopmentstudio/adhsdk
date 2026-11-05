import Foundation

public enum ChatUpdate: Sendable {
    case messagesChanged
    case participantsChanged
    case typingChanged
    case readMarkersChanged
    case activeDraftsChanged
    case pendingPermissionsChanged
    case pendingWidgetsChanged
    case displayConfigChanged

    /// `commandActivity` changed: a command was invoked, or one already
    /// running produced a result. One case covers both because a pill
    /// re-renders from the whole array either way — the running/finished
    /// split lives on `CommandActivity.isRunning`, not in the update.
    case commandActivityChanged

    /// `statuses[participantID]` changed — a turn started thinking, moved to
    /// another kind of work, or settled.
    ///
    /// **Out-of-band still means "not a message", not "not observable".** A
    /// status never enters `messages` and never commits a draft; that is the
    /// invariant `ObservableChatViewModelTests.statusChangedIsOutOfBand`
    /// pins, and it holds. What it cannot also mean is "no observer hears
    /// it": web reaches the same line through an `onStatus` callback the
    /// view subscribes to, and without a case here a Swift view has no
    /// signal at all — `ThinkingIndicatorView.update(status:)` had no caller
    /// anywhere in the toolkit, so a persona's authored vocabulary reached
    /// the view model and stopped there.
    ///
    /// Carries the participant rather than the `ChatStatus` itself, matching
    /// every other case: an observer re-reads `statuses` the way
    /// `.messagesChanged` has it re-read `messages`.
    case statusChanged(participantID: String)

    case error(message: String)
}
