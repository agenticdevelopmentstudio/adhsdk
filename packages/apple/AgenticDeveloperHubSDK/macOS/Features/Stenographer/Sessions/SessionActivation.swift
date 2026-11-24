import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS

import Foundation

/// "Take me to that session": brings a session's terminal tab forward, given
/// only its id.
///
/// The one route the toolkit has from a session id to the session itself. The
/// Conversations window's row action uses it, and so does anything outside the
/// toolkit that holds an id and nothing else — the Git window's agent sessions.
@MainActor
public enum SessionActivation {

    /// Brings session `id` forward — the terminal tab it is running in, found
    /// the way the Sessions window finds it. Nil when it went there, or the
    /// reason it could not.
    ///
    /// Always `.activateWindow`, whatever `UserSettings.clickAction` says: that
    /// pref is the Sessions list's, and it can name actions — open a fresh
    /// terminal, run a command — that are the wrong answer to "take me there".
    ///
    /// The handler is left on its default of no Accessibility, as the Sessions
    /// window's is: an iTerm2 or Terminal.app session's tab is selected by
    /// Apple Event, and any other terminal is brought forward whole. Checking
    /// for an Accessibility grant Stenographer never asks for stalls tccd, and
    /// with it the whole machine, for ~10s.
    public static func activate(id: String, service: any StenographerDaemonService) async -> String? {
        // The id alone is not enough: the activation needs the session's
        // terminal identity (pid, term program, tab id), which lives on the
        // session record. One row by id, without the event count activation
        // never reads.
        guard let found = await service.session(id: id, includeCounts: false) else {
            return "Couldn't reach the daemon — it may be restarting. Try again."
        }
        guard let dto = found else {
            return "The daemon has no record of this session any more."
        }
        let handler = SessionWatcher.SessionWatcherActionHandler(
            settingsStore: UserSettings.shared,
            usesAccessibility: false
        )
        let result = handler.execute(
            action: .activateWindow,
            for: StenographerSessionListSource.session(from: dto)
        )
        if case .failure(let error) = result {
            return error.localizedDescription
        }
        return nil
    }
}
